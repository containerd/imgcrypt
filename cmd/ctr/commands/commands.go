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

package commands

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/containerd/containerd/v2/pkg/atomicfile"

	"github.com/urfave/cli/v2"
)

// ObjectWithLabelArgs returns the first arg and a LabelArgs object
func ObjectWithLabelArgs(clicontext *cli.Context) (string, map[string]string) {
	var (
		first        = clicontext.Args().First()
		labelStrings = clicontext.Args().Tail()
	)

	return first, LabelArgs(labelStrings)
}

// LabelArgs returns a map of label key,value pairs
func LabelArgs(labelStrings []string) map[string]string {
	labels := make(map[string]string, len(labelStrings))
	for _, label := range labelStrings {
		parts := strings.SplitN(label, "=", 2)
		key := parts[0]
		value := "true"
		if len(parts) > 1 {
			value = parts[1]
		}

		labels[key] = value
	}

	return labels
}

// AnnotationArgs returns a map of annotation key,value pairs.
func AnnotationArgs(annoStrings []string) (map[string]string, error) {
	annotations := make(map[string]string, len(annoStrings))
	for _, anno := range annoStrings {
		parts := strings.SplitN(anno, "=", 2)
		if len(parts) != 2 {
			return nil, fmt.Errorf("invalid key=value format annotation: %v", anno)
		}
		annotations[parts[0]] = parts[1]
	}
	return annotations, nil
}

// PrintAsJSON prints input in JSON format
func PrintAsJSON(x interface{}) {
	b, err := json.MarshalIndent(x, "", "    ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "can't marshal %+v as a JSON string: %v\n", x, err)
	}
	fmt.Println(string(b))
}

// WritePidFile writes the pid atomically to a file
func WritePidFile(path string, pid int) error {
	path, err := filepath.Abs(path)
	if err != nil {
		return err
	}
	f, err := atomicfile.New(path, 0o666)
	if err != nil {
		return err
	}
	_, err = fmt.Fprintf(f, "%d", pid)
	if err != nil {
		f.Cancel()
		return err
	}
	return f.Close()
}
