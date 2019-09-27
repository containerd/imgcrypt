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

package flags

import (
	"github.com/urfave/cli"
)

var (
	// ImageDecryptionFlags are cli flags needed when decrypting an image
	ImageDecryptionFlags = []cli.Flag{
		cli.StringFlag{
			Name:  "gpg-homedir",
			Usage: "The GPG homedir to use; by default gpg uses ~/.gnupg",
		}, cli.StringFlag{
			Name:  "gpg-version",
			Usage: "The GPG version (\"v1\" or \"v2\"), default will make an educated guess",
		}, cli.StringSliceFlag{
			Name:  "key",
			Usage: "A secret key's filename and an optional password separated by colon; this option may be provided multiple times",
		}, cli.StringSliceFlag{
			Name:  "dec-recipient",
			Usage: "Recipient of the image; used only for PKCS7 and must be an x509 certificate",
		},
	}
)
