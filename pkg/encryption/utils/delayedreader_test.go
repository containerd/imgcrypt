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

package utils

import (
	"bytes"
	"io"
	"reflect"
	"testing"
)

func makeRangeExp(n int) []int {
	var res []int
	for i := 0; i < n; i++ {
		res = append(res, 1<<uint(i))
	}
	return res
}

func makeRange(lo, hi int) []int {
	var res []int
	for i := lo; i < hi; i++ {
		res = append(res, i)
	}
	return res
}

func TestDelayedReader(t *testing.T) {
	buf := make([]byte, 10)

	for _, buflen := range makeRangeExp(20) {
		obuf := make([]byte, buflen)

		for _, bufsize := range makeRange(2, 32) {
			r := bytes.NewReader(obuf)

			dr := NewDelayedReader(r, uint(bufsize))

			var ibuf []byte
			for {
				n, err := dr.Read(buf)
				if n == 0 {
					t.Fatal("Did not expect n == 0")
				}
				if err != nil && err != io.EOF {
					t.Fatal(err)
				}
				ibuf = append(ibuf, buf[:n]...)
				if err == io.EOF {
					break
				}
			}
			if !reflect.DeepEqual(ibuf, obuf) {
				t.Fatalf("original buffer (len=%d) != received buffer (len=%d)", len(obuf), len(ibuf))
			}
		}
	}
}
