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
	"github.com/containerd/typeurl"
	"github.com/gogo/protobuf/proto"
	"github.com/gogo/protobuf/types"
	"github.com/pkg/errors"
)

func main() {
	if err := decrypt(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func decrypt() error {
	payload, err := getPayload()
	if err != nil {
		return err
	}

	_, r, _, err := encryption.DecryptLayer(&payload.DecryptConfig, os.Stdin, payload.Descriptor, false)
	if err != nil {
		return errors.Wrapf(err, "call to DecryptLayer failed")
	}

	for {
		_, err := io.CopyN(os.Stdout, r, 10*1024)
		if err != nil {
			if err == io.EOF {
				break
			}
			return errors.Wrapf(err, "could not copy data")
		}
	}
	return nil
}

func getPayload() (*imgcrypt.Payload, error) {
	data, err := readPayload()
	if err != nil {
		return nil, errors.Wrap(err, "read payload")
	}
	var any types.Any
	if err := proto.Unmarshal(data, &any); err != nil {
		return nil, errors.Wrapf(err, "could not proto.Unmarshal() decrypt data")
	}
	v, err := typeurl.UnmarshalAny(&any)
	if err != nil {
		return nil, errors.Wrapf(err, "could not UnmarshalAny() the decrypt data")
	}
	l, ok := v.(*imgcrypt.Payload)
	if !ok {
		return nil, errors.Errorf("unknown payload type %s", any.TypeUrl)
	}
	return l, nil
}
