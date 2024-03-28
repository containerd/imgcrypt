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

// Package v2v1glue is a temporary package for using containerd v2 packages from v1.
package v2v1glue

import (
	"context"

	"github.com/containerd/containerd"
	"github.com/containerd/containerd/diff"
	"github.com/containerd/containerd/snapshots"
	v2containerd "github.com/containerd/containerd/v2/client"
	v2diff "github.com/containerd/containerd/v2/core/diff"
	v2snapshots "github.com/containerd/containerd/v2/core/snapshots"
	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
)

func applyConfig(v2ac *v2diff.ApplyConfig) *diff.ApplyConfig {
	if v2ac == nil {
		return nil
	}
	ac := diff.ApplyConfig(*v2ac)
	return &ac
}

func snapshotsInfo(v2info *v2snapshots.Info) *snapshots.Info {
	if v2info == nil {
		return nil
	}
	info := snapshots.Info{
		Kind:    snapshots.Kind(v2info.Kind),
		Name:    v2info.Name,
		Parent:  v2info.Parent,
		Labels:  v2info.Labels,
		Created: v2info.Created,
		Updated: v2info.Updated,
	}
	return &info
}

func v2unpackConfig(config *containerd.UnpackConfig) *v2containerd.UnpackConfig {
	if config == nil {
		return nil
	}

	applyOpts := make([]v2diff.ApplyOpt, len(config.ApplyOpts))
	for i, f := range config.ApplyOpts {
		i, f := i, f
		applyOpts[i] = func(ctx context.Context, desc ocispec.Descriptor, v2ac *v2diff.ApplyConfig) error {
			return f(ctx, desc, applyConfig(v2ac))
		}
	}

	snapshotOpts := make([]v2snapshots.Opt, len(config.SnapshotOpts))
	for i, f := range config.SnapshotOpts {
		i, f := i, f
		snapshotOpts[i] = func(v2info *v2snapshots.Info) error {
			return f(snapshotsInfo(v2info))
		}
	}

	return &v2containerd.UnpackConfig{
		ApplyOpts:              applyOpts,
		SnapshotOpts:           snapshotOpts,
		CheckPlatformSupported: config.CheckPlatformSupported,
		DuplicationSuppressor:  config.DuplicationSuppressor,
	}
}

func UnpackOpt(v2opt v2containerd.UnpackOpt) containerd.UnpackOpt {
	return func(ctx context.Context, config *containerd.UnpackConfig) error {
		return v2opt(ctx, v2unpackConfig(config))
	}
}

func UnpackOpts(v2opts ...v2containerd.UnpackOpt) []containerd.UnpackOpt {
	opts := make([]containerd.UnpackOpt, len(v2opts))
	for i, f := range v2opts {
		i, f := i, f
		opts[i] = UnpackOpt(f)
	}
	return opts
}
