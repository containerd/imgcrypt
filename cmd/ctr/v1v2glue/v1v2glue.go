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

// Package v1v2glue is a temporary package for using containerd v1 packages from v2.
package v1v2glue

import (
	"context"

	v1content "github.com/containerd/containerd/content"
	"github.com/containerd/containerd/v2/core/content"
	"github.com/opencontainers/go-digest"
	ocispec "github.com/opencontainers/image-spec/specs-go/v1"
)

type ContentStore struct {
	v1content.Store
}

var _ content.Store = &ContentStore{}

func (cs *ContentStore) Info(ctx context.Context, dgst digest.Digest) (content.Info, error) {
	v1Info, err := cs.Store.Info(ctx, dgst)
	return content.Info(v1Info), err
}

func (cs *ContentStore) ListStatuses(ctx context.Context, filters ...string) ([]content.Status, error) {
	v1Statuses, err := cs.Store.ListStatuses(ctx, filters...)
	statuses := make([]content.Status, len(v1Statuses))
	for i, f := range v1Statuses {
		statuses[i] = content.Status(f)
	}
	return statuses, err
}

func (cs *ContentStore) ReaderAt(ctx context.Context, desc ocispec.Descriptor) (content.ReaderAt, error) {
	v1ra, err := cs.Store.ReaderAt(ctx, desc)
	return v1ra.(content.ReaderAt), err
}

func (cs *ContentStore) Status(ctx context.Context, ref string) (content.Status, error) {
	v1s, err := cs.Store.Status(ctx, ref)
	return content.Status(v1s), err
}

func (cs *ContentStore) Update(ctx context.Context, info content.Info, fieldpaths ...string) (content.Info, error) {
	v1res, err := cs.Store.Update(ctx, v1content.Info(info), fieldpaths...)
	return content.Info(v1res), err
}

func (cs *ContentStore) Walk(ctx context.Context, wf content.WalkFunc, filters ...string) error {
	v1wf := func(v1info v1content.Info) error {
		return wf(content.Info(v1info))
	}
	return cs.Store.Walk(ctx, v1wf, filters...)
}

func (cs *ContentStore) Writer(ctx context.Context, opts ...content.WriterOpt) (content.Writer, error) {
	v1opts := make([]v1content.WriterOpt, len(opts))
	for i, f := range opts {
		i, f := i, f
		v1opts[i] = func(v1wo *v1content.WriterOpts) error {
			if v1wo == nil {
				return f(nil)
			}
			wo := content.WriterOpts(*v1wo)
			err := f(&wo)
			*v1wo = v1content.WriterOpts(wo)
			return err
		}
	}
	v1w, err := cs.Store.Writer(ctx, v1opts...)
	return &ContentWriter{Writer: v1w}, err
}

type ContentWriter struct {
	v1content.Writer
}

func (cw *ContentWriter) Commit(ctx context.Context, size int64, expected digest.Digest, opts ...content.Opt) error {
	v1opts := make([]v1content.Opt, len(opts))
	for i, f := range opts {
		i, f := i, f
		v1opts[i] = func(v1info *v1content.Info) error {
			if v1info == nil {
				return f(nil)
			}
			info := content.Info(*v1info)
			err := f(&info)
			*v1info = v1content.Info(info)
			return err
		}
	}
	return cw.Writer.Commit(ctx, size, expected, v1opts...)
}

func (cw *ContentWriter) Status() (content.Status, error) {
	v1s, err := cw.Writer.Status()
	return content.Status(v1s), err
}
