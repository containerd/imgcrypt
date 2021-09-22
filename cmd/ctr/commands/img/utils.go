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

package img

import (
	"context"
	"fmt"

	"github.com/containerd/containerd/content"
	"github.com/containerd/containerd/errdefs"
	"github.com/containerd/containerd/images"
	"github.com/containerd/containerd/platforms"

	encocispec "github.com/containers/ocicrypt/spec"
	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
)

// GetImageLayerDescriptors gets the image layer Descriptors of an image; the array contains
// a list of Descriptors belonging to one platform followed by lists of other platforms
func GetImageLayerDescriptors(ctx context.Context, cs content.Store, desc ocispec.Descriptor) ([]ocispec.Descriptor, error) {
	var lis []ocispec.Descriptor

	ds := platforms.DefaultSpec()
	platform := &ds

	switch desc.MediaType {
	case images.MediaTypeDockerSchema2ManifestList, ocispec.MediaTypeImageIndex,
		images.MediaTypeDockerSchema2Manifest, ocispec.MediaTypeImageManifest:
		children, err := images.Children(ctx, cs, desc)
		if err != nil {
			if errdefs.IsNotFound(err) {
				return []ocispec.Descriptor{}, nil
			}
			return []ocispec.Descriptor{}, err
		}

		if desc.Platform != nil {
			platform = desc.Platform
		}

		for _, child := range children {
			var tmp []ocispec.Descriptor

			switch child.MediaType {
			case images.MediaTypeDockerSchema2LayerGzip, images.MediaTypeDockerSchema2Layer,
				ocispec.MediaTypeImageLayerGzip, ocispec.MediaTypeImageLayer,
				encocispec.MediaTypeLayerGzipEnc, encocispec.MediaTypeLayerEnc:
				tdesc := child
				tdesc.Platform = platform
				tmp = append(tmp, tdesc)
			default:
				tmp, err = GetImageLayerDescriptors(ctx, cs, child)
			}

			if err != nil {
				return []ocispec.Descriptor{}, err
			}

			lis = append(lis, tmp...)
		}
	case images.MediaTypeDockerSchema2Config, ocispec.MediaTypeImageConfig:
	default:
		return nil, fmt.Errorf("unhandled media type %s: %w", desc.MediaType, errdefs.ErrInvalidArgument)
	}
	return lis, nil
}
