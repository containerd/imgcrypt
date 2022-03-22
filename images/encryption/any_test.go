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

	"github.com/gogo/protobuf/types"
)

func TestFromAny(t *testing.T) {
	pbany := &types.Any{}

	var testcases = []struct {
		input    any
		expected *types.Any
	}{
		{input: nil, expected: nil},
		{input: pbany, expected: pbany},
	}

	for _, tc := range testcases {
		actual := fromAny(tc.input)
		if actual != tc.expected {
			t.Fatalf("expected %v, but got %v", tc.expected, actual)
		}
	}
}
