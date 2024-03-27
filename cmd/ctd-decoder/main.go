/*
   Copyright The containerd Authors.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

package main

import (
	"fmt"
	"io"
	"os"

	"github.com/containerd/imgcrypt"
	"github.com/containerd/imgcrypt/images/encryption"
	"github.com/containerd/typeurl/v2"

	"github.com/containerd/containerd/v2/protobuf/proto"
	"github.com/containerd/containerd/v2/protobuf/types"
	"github.com/urfave/cli/v2"
)

var (
	Usage = "ctd-decoder is used as a call-out from containerd content stream plugins"
)

func main() {
	app := cli.NewApp()
	app.Name = "ctd-decoder"
	app.Usage = Usage
	app.Action = run
	app.Flags = []cli.Flag{
		&cli.StringFlag{
			Name:  "decryption-keys-path",
			Usage: "Path to load decryption keys from. (optional)",
		},
	}
	if err := app.Run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func run(ctx *cli.Context) error {
	if err := decrypt(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
		return err
	}
	return nil
}

func decrypt(ctx *cli.Context) error {
	payload, err := getPayload()
	if err != nil {
		return err
	}

	decCc := &payload.DecryptConfig

	// TODO: If decryption key path is set, get additional keys to augment payload keys
	if ctx.IsSet("decryption-keys-path") {
		keyPathCc, err := getDecryptionKeys(ctx.String("decryption-keys-path"))
		if err != nil {
			return fmt.Errorf("unable to get decryption keys in provided key path: %w", err)
		}
		decCc = combineDecryptionConfigs(keyPathCc.DecryptConfig, &payload.DecryptConfig)
	}

	_, r, _, err := encryption.DecryptLayer(decCc, os.Stdin, payload.Descriptor, false)
	if err != nil {
		return fmt.Errorf("call to DecryptLayer failed: %w", err)
	}

	for {
		_, err := io.CopyN(os.Stdout, r, 10*1024)
		if err != nil {
			if err == io.EOF {
				break
			}
			return fmt.Errorf("could not copy data: %w", err)
		}
	}
	return nil
}

func getPayload() (*imgcrypt.Payload, error) {
	data, err := readPayload()
	if err != nil {
		return nil, fmt.Errorf("read payload: %w", err)
	}
	var anything types.Any
	if err := proto.Unmarshal(data, &anything); err != nil {
		return nil, fmt.Errorf("could not proto.Unmarshal() decrypt data: %w", err)
	}
	v, err := typeurl.UnmarshalAny(&anything)
	if err != nil {
		return nil, fmt.Errorf("could not UnmarshalAny() the decrypt data: %w", err)
	}
	l, ok := v.(*imgcrypt.Payload)
	if !ok {
		return nil, fmt.Errorf("unknown payload type %s", anything.TypeUrl)
	}
	return l, nil
}
