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

package encryption

import (
	"context"

	"github.com/containerd/containerd"
	"github.com/containerd/containerd/containers"
	"github.com/containerd/containerd/diff"
	"github.com/containerd/containerd/errdefs"
	encconfig "github.com/containerd/ocicrypt/pkg/encryption/config"
	"github.com/containerd/typeurl"
	"github.com/gogo/protobuf/types"
	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
	"github.com/pkg/errors"
)

// LayerToolDecryptData holds data that the external layer decryption tool
// needs for decrypting a layer
type LayerToolDecryptData struct {
	DecryptConfig encconfig.DecryptConfig
	Descriptor    ocispec.Descriptor
}

func init() {
	typeurl.Register(&LayerToolDecryptData{}, "LayerToolDecryptData")
}

// WithDecryptedUnpack allows to pass parameters the 'layertool' needs to the applier
func WithDecryptedUnpack(data *LayerToolDecryptData) diff.ApplyOpt {
	return func(_ context.Context, desc ocispec.Descriptor, c *diff.ApplyConfig) error {
		if c.ProcessorPayloads == nil {
			c.ProcessorPayloads = make(map[string]*types.Any)
		}
		data.Descriptor = desc
		any, err := typeurl.MarshalAny(data)
		if err != nil {
			return errors.Wrapf(err, "failed to typeurl.MarshalAny(LayerToolDecryptData)")
		}

		c.ProcessorPayloads["io.containerd.layertool.tar"] = any
		c.ProcessorPayloads["io.containerd.layertool.tar.gzip"] = any

		return nil
	}
}

// WithUnpackConfigApplyOpts allows to pass an ApplyOpt
func WithUnpackConfigApplyOpts(opt diff.ApplyOpt) containerd.UnpackOpt {
	return func(_ context.Context, uc *containerd.UnpackConfig) error {
		uc.ApplyOpts = append(uc.ApplyOpts, opt)
		return nil
	}
}

// WithAuthorizationCheck checks the authorization of keys used for encrypted containers
// be checked upon creation of a container
func WithAuthorizationCheck(dcparameters map[string][][]byte) containerd.NewContainerOpts {
	return func(ctx context.Context, client *containerd.Client, c *containers.Container) error {
		image, err := client.ImageService().Get(ctx, c.Image)
		if errdefs.IsNotFound(err) {
			// allow creation of container without a existing image
			return nil
		} else if err != nil {
			return err
		}

		dc := encconfig.DecryptConfig{
			Parameters: dcparameters,
		}

		return CheckAuthorization(ctx, client.ContentStore(), image.Target, &dc)
	}
}
