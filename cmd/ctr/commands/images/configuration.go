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
	"io/ioutil"
	"os"
	"path"

	"github.com/containers/ocicrypt/crypto/pkcs11"
	"gopkg.in/yaml.v2"
)

// ImgcryptoConfig represents the format of an imgcrypt.conf config file
type ImgcryptConfig struct {
	Pkcs11Config pkcs11.Pkcs11Config `yaml:"pkcs11"`
}

// parseConfigFile parses a configuration file; it is not an error if the configuration file does
// not exist, so no error is returned.
func parseConfigFile(filename string) (*ImgcryptConfig, error) {
	// a non-existent config file is not an error
	_, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return nil, nil
	}

	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	ic := &ImgcryptConfig{}
	err = yaml.Unmarshal(data, ic)
	return ic, err
}

// getConfiguration tries to read the configuration file at the following locations
// 1) environment variable IMGCRYPT_CONFIG
// 2) environment variable XDG_CONFIG_HOME/imgcrypt.conf
// 3) environment variable HOME/.config/imgcrypt.conf
// 4) /etc/imgcrypt.conf
// If no configuration file could be found or read a null pointer is returned
func getConfiguration() (*ImgcryptConfig, error) {
	filename := os.Getenv("IMGCRYPT_CONFIG")
	if len(filename) > 0 {
		ic, err := parseConfigFile(filename)
		if err != nil || ic != nil {
			return ic, nil
		}
	}
	envvar := os.Getenv("XDG_CONFIG_HOME")
	if len(envvar) > 0 {
		ic, err := parseConfigFile(path.Join(envvar, "imgcrypt.conf"))
		if err != nil || ic != nil {
			return ic, nil
		}
	}
	envvar = os.Getenv("HOME")
	if len(envvar) > 0 {
		ic, err := parseConfigFile(path.Join(envvar, ".config", "imgcrypt.conf"))
		if err != nil || ic != nil {
			return ic, nil
		}
	}
	return parseConfigFile(path.Join("etc", "imgcrypt.conf"))
}

// getDefaultCryptoConfigOpts returns default crypto config opts needed for pkcs11 module access
func getDefaultCryptoConfigOpts() (CryptoConfigOpts, error) {
	config := `module-directories:
 - /usr/lib64/pkcs11/  # Fedora,RedHat,openSUSE
 - /usr/lib/softhsm/   # Ubuntu,Debian,Alpine
`
	p11conf, err := pkcs11.ParsePkcs11ConfigFile([]byte(config))
	if err != nil {
		return CryptoConfigOpts{}, err
	}
	return CryptoConfigOpts{
		Pkcs11Config: p11conf,
	}, nil
}

// GetCryptoConfigOpts gets the CryptoConfigOpts either from a configuration file or if none is
// found the default ones are returned
func GetCryptoConfigOpts() (CryptoConfigOpts, error) {
	ic, err := getConfiguration()
	if err != nil {
		return CryptoConfigOpts{}, err
	}
	if ic == nil {
		return getDefaultCryptoConfigOpts()
	}
	return CryptoConfigOpts{
		Pkcs11Config: &ic.Pkcs11Config,
	}, nil
}
