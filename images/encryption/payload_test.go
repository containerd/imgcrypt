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
	"testing"

	"github.com/containerd/containerd/diff"
	"github.com/gogo/protobuf/types"
)

func TestInit(t *testing.T) {
	if !processorPayloadsUseGogo {
		t.Fatalf("failed to detect gogo: %v", processorPayloadsUseGogo)
	}
}

func TestClear(t *testing.T) {
	var ac diff.ApplyConfig
	clearProcessorPayloads(&ac)
	if ac.ProcessorPayloads == nil {
		t.Fatalf("ProcessorPayloads must have a map, but got %v", ac.ProcessorPayloads)
	}

	_, ok := ac.ProcessorPayloads["hello"]
	if ok {
		t.Fatalf("expected false, but got %v", ok)
	}
}

func TestSet(t *testing.T) {
	var ac diff.ApplyConfig

	expected := &types.Any{}
	setProcessorPayload(&ac, "hello", expected)

	got, ok := ac.ProcessorPayloads["hello"]
	if !ok {
		t.Fatalf("expected false, but got %v", ok)
	}

	if got != expected {
		t.Fatalf("expected %v, but got %v", expected, got)
	}
}
