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

package images

import (
	gocontext "context"

	"strings"

	"github.com/containerd/containerd"
	"github.com/containerd/containerd/images"
	"github.com/containerd/containerd/platforms"
	"github.com/containerd/imgcrypt/cmd/ctr/commands/img"
	imgenc "github.com/containerd/imgcrypt/images/encryption"
	encconfig "github.com/containers/ocicrypt/config"

	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
)

// LayerInfo holds information about an image layer
type LayerInfo struct {
	// The Number of this layer in the sequence; starting at 0
	Index      uint32
	Descriptor ocispec.Descriptor
}

// isUserSelectedLayer checks whether a layer is user-selected given its number
// A layer can be described with its (positive) index number or its negative number.
// The latter is counted relative to the topmost one (-1), the former relative to
// the bottommost one (0).
func isUserSelectedLayer(layerIndex, layersTotal int32, layers []int32) bool {
	if len(layers) == 0 {
		// convenience for the user; none given means 'all'
		return true
	}
	negNumber := layerIndex - layersTotal

	for _, l := range layers {
		if l == negNumber || l == layerIndex {
			return true
		}
	}
	return false
}

// isUserSelectedPlatform determines whether the platform matches one in
// the array of user-provided platforms
func isUserSelectedPlatform(platform *ocispec.Platform, platformList []ocispec.Platform) bool {
	if len(platformList) == 0 {
		// convenience for the user; none given means 'all'
		return true
	}
	matcher := platforms.NewMatcher(*platform)

	for _, platform := range platformList {
		if matcher.Match(platform) {
			return true
		}
	}
	return false
}

func createLayerFilter(client *containerd.Client, ctx gocontext.Context, desc ocispec.Descriptor, layers []int32, platformList []ocispec.Platform) (imgenc.LayerFilter, error) {
	alldescs, err := img.GetImageLayerDescriptors(ctx, client.ContentStore(), desc)
	if err != nil {
		return nil, err
	}

	_, descs := filterLayerDescriptors(alldescs, layers, platformList)

	lf := func(d ocispec.Descriptor) bool {
		for _, desc := range descs {
			if desc.Digest.String() == d.Digest.String() {
				return true
			}
		}
		return false
	}
	return lf, nil
}

// cryptImage encrypts or decrypts an image with the given name and stores it either under the newName
// or updates the existing one
func cryptImage(client *containerd.Client, ctx gocontext.Context, name, newName string, cc *encconfig.CryptoConfig, layers []int32, platformList []string, encrypt bool) (images.Image, error) {
	s := client.ImageService()

	image, err := s.Get(ctx, name)
	if err != nil {
		return images.Image{}, err
	}

	pl, err := parsePlatformArray(platformList)
	if err != nil {
		return images.Image{}, err
	}

	lf, err := createLayerFilter(client, ctx, image.Target, layers, pl)
	if err != nil {
		return images.Image{}, err
	}

	var (
		modified bool
		newSpec  ocispec.Descriptor
	)

	ctx, done, err := client.WithLease(ctx)
	if err != nil {
		return images.Image{}, err
	}
	defer done(ctx)

	if encrypt {
		newSpec, modified, err = imgenc.EncryptImage(ctx, client.ContentStore(), image.Target, cc, lf)
	} else {
		newSpec, modified, err = imgenc.DecryptImage(ctx, client.ContentStore(), image.Target, cc, lf)
	}
	if err != nil {
		return image, err
	}
	if !modified {
		return image, nil
	}

	image.Target = newSpec

	// if newName is either empty or equal to the existing name, it's an update
	if newName == "" || strings.Compare(image.Name, newName) == 0 {
		// first Delete the existing and then Create a new one
		// We have to do it this way since we have a newSpec!
		err = s.Delete(ctx, image.Name)
		if err != nil {
			return images.Image{}, err
		}
		newName = image.Name
	}

	image.Name = newName
	return s.Create(ctx, image)
}

func encryptImage(client *containerd.Client, ctx gocontext.Context, name, newName string, cc *encconfig.CryptoConfig, layers []int32, platformList []string) (images.Image, error) {
	return cryptImage(client, ctx, name, newName, cc, layers, platformList, true)
}

func decryptImage(client *containerd.Client, ctx gocontext.Context, name, newName string, cc *encconfig.CryptoConfig, layers []int32, platformList []string) (images.Image, error) {
	return cryptImage(client, ctx, name, newName, cc, layers, platformList, false)
}

func getImageLayerInfos(client *containerd.Client, ctx gocontext.Context, name string, layers []int32, platformList []string) ([]LayerInfo, []ocispec.Descriptor, error) {
	s := client.ImageService()

	image, err := s.Get(ctx, name)
	if err != nil {
		return nil, nil, err
	}

	pl, err := parsePlatformArray(platformList)
	if err != nil {
		return nil, nil, err
	}

	alldescs, err := img.GetImageLayerDescriptors(ctx, client.ContentStore(), image.Target)
	if err != nil {
		return nil, nil, err
	}

	lis, descs := filterLayerDescriptors(alldescs, layers, pl)
	return lis, descs, nil
}

func countLayers(descs []ocispec.Descriptor, platform *ocispec.Platform) int32 {
	c := int32(0)

	for _, desc := range descs {
		if desc.Platform == platform {
			c = c + 1
		}
	}

	return c
}

func filterLayerDescriptors(alldescs []ocispec.Descriptor, layers []int32, pl []ocispec.Platform) ([]LayerInfo, []ocispec.Descriptor) {
	var (
		layerInfos  []LayerInfo
		descs       []ocispec.Descriptor
		curplat     *ocispec.Platform
		layerIndex  int32
		layersTotal int32
	)

	for _, desc := range alldescs {
		if curplat != desc.Platform {
			curplat = desc.Platform
			layerIndex = 0
			layersTotal = countLayers(alldescs, desc.Platform)
		} else {
			layerIndex = layerIndex + 1
		}

		if isUserSelectedLayer(layerIndex, layersTotal, layers) && isUserSelectedPlatform(curplat, pl) {
			li := LayerInfo{
				Index:      uint32(layerIndex),
				Descriptor: desc,
			}
			descs = append(descs, desc)
			layerInfos = append(layerInfos, li)
		}
	}
	return layerInfos, descs
}

// parsePlatformArray parses an array of specifiers and converts them into an array of specs.Platform
func parsePlatformArray(specifiers []string) ([]ocispec.Platform, error) {
	var speclist []ocispec.Platform

	for _, specifier := range specifiers {
		spec, err := platforms.Parse(specifier)
		if err != nil {
			return []ocispec.Platform{}, err
		}
		speclist = append(speclist, spec)
	}
	return speclist, nil
}
