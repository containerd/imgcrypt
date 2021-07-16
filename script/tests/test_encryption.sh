#!/usr/bin/env bash

#   Copyright The containerd Authors.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

sudo -v
if [ $? -ne 0 ]; then
	echo "Need to be able to use sudo."
	exit 1
fi

if [ -z ${CONTAINERD} ] || [ ! -x ${CONTAINERD} ]; then
	echo "CONTAINERD env. variable must have path to containerd"
	exit 1
fi

ROOT=$(dirname "$0")/../../
BIN=${ROOT}/bin

SOFTHSM_SETUP=$(dirname "$0")/softhsm_setup

ALPINE=docker.io/library/alpine:latest
ALPINE_ENC=docker.io/library/alpine:enc
ALPINE_DEC=docker.io/library/alpine:dec
ALPINE_ENC_EXPORT_NAME=alpine.enc
ALPINE_ENC_IMPORT_BASE=docker.io/library/alpine

NGINX=docker.io/library/nginx:latest
NGINX_ENC=docker.io/library/nginx:enc
NGINX_DEC=docker.io/library/nginx:dec

# gpg2 --export-secret-key ...
GPGTESTKEY1="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"
GPGTESTKEY2="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"

JWKTESTKEY1='{"d":"pGBXnqbPbMR6PIPkyzz1OhmJq4ORmlHwh2GunXJuzSj1AhYL9rZ8fd_NNn128yPmllTN6LOBqNj1vqXOnMaeu63vdn08z8xTDlCsuUt2T0NzgQlPuducu8K0OURFqf-C3dIPqipxnWKydN7_gYEEYosxgKU3B8WolA65YFTaUxv-NQL-3rASUTtiQ1rtm2l-RBEIqOuFh350Bahnq_gtINxKpVahpLDiLTte6HpnbzU7ei_dW4v3j6foMg2pOWUAcfxNfmZwQO-eEge88E5WfN7HIQnBTTjAjrNwIP-SfaDmKpa37at1kTG932If0VopQ9CJZE_jM2wHx3VfZiTmAQ","dp":"RFUZdzAaCs3ak4lxptnHy5J_ujWgHk1CvzyIU1tEw1P9BCme-pW30YdEvXkXMzqiX8g0p6WdEvbfx0I9dctje9IbjCQcemxjIUx-2ifUppp8_I4BCaZ4K4puyt65TJL2za6PmyuVTDlugYceMIupmZ4bx6C70bjTeo1ErVe-yYE","dq":"zOCBbLcqCtkXUQqlmOEmb35GBc5HLV6LcQSYAm1mhMIRjK-cSiXAlg4yKhXoGNAuU-LBXyVLeOa4cNdG_v-34XZGmqIyBWG1ehmMumcblzI2-Cuj76jW26sWBvPBH7cyEf1FULS3acF-xPd8TkNA9P0laZmCshOfa_-zkMM5Tf8","e":"AQAB","kty":"RSA","n":"zMwIcZn24y3Aj-P5Vox-w54FkpoRGeYGhyF7rdDQN2bYO-8h09doVbbgstYauyZKRvk3iWoOwfY9foD0hHCJNtT20sqbx40osGN9qLERweO6Xn8adhVPN7isTT9KozdvsrOIBr7uQUsruvow4klIYrv5FqS_RHpy4f0CUlsjPqc3F5PC4yV0D0f_QUApr06--uHRdH3ucunvdwR1V1IZV0DEJwZ5DzEDQmynzo5oV1UVNb9DSzTXsUAzSipCrdIyUxCnofPp_PzKvqMbctBAchx0AKN8IK8Z3RGFYyrV3HxkXqFxZ4aTVnkXqlnGV5CRQhx59ckIWUxAlyLcGLXvmw","p":"_aCnqjENQBE-he_7XWBo7kXJHnOz6SucuLNPo35imTO4nJBkga9HOF8VxeM3OrskEFVudkDvSqbq4KtERiCGL8f3-LAUKSFaxULa0h9FPJOlks_JXVlDwGsXOyHirIHIEvvbjAAQlV_F7tQNCzSHuXmegh3yJWLwz6EcUw2z9YE","q":"zrZyXsm2jVHc9JkWEp8CMJ0J65f87KrYjQgcb46XkCK1E7bnFDLiNzYV-CQ8a9kKuWfd_LUx2FIjwrik5IFQXJA7Z7s4jvAh2J-pLutSD4sU0KAXcH8W85jLd9C0varGXWFFD7axv-FjDEEQ8TL35Nh5svILn_hgMfB2TPNuixs","qi":"GgGk6GPOtfo2TFtuPQPVTTPGmEzoVekZNH9VQfvQchiRyU1cddYWGRzzJct1zP0GhRsam7m27zguxxVVOORjM5NAPHhjhuwmncmi5hZDyfyIURPXOgslPNG42XdIZdfJtgxqUuOhLNfeQcQXJM8S2EpauLmlm14blP5V-7ZOXO0"}'

JWKTESTPUBKEY1='{"e":"AQAB","kty":"RSA","n":"zMwIcZn24y3Aj-P5Vox-w54FkpoRGeYGhyF7rdDQN2bYO-8h09doVbbgstYauyZKRvk3iWoOwfY9foD0hHCJNtT20sqbx40osGN9qLERweO6Xn8adhVPN7isTT9KozdvsrOIBr7uQUsruvow4klIYrv5FqS_RHpy4f0CUlsjPqc3F5PC4yV0D0f_QUApr06--uHRdH3ucunvdwR1V1IZV0DEJwZ5DzEDQmynzo5oV1UVNb9DSzTXsUAzSipCrdIyUxCnofPp_PzKvqMbctBAchx0AKN8IK8Z3RGFYyrV3HxkXqFxZ4aTVnkXqlnGV5CRQhx59ckIWUxAlyLcGLXvmw"}'

trap "cleanup" EXIT QUIT

cleanup() {
	if [ -n "$CONTAINERD_PID" ]; then
		sudo kill -9 ${CONTAINERD_PID}
	fi
	if [ -n "${WORKDIR}" ]; then
		sudo rm -rf ${WORKDIR}
	fi
	echo "Clean up complete"
	echo
}

setup() {
	WORKDIR=$(mktemp -d)
	CONFIG_TOML=${WORKDIR}/config.toml
	CONTAINERD_SOCKET=${WORKDIR}/containerd.socket
	ROOTDIR=${WORKDIR}/var/lib/containerd
	STATEDIR=${WORKDIR}/run/containerd
	LOGFILE=${WORKDIR}/log
	PIDFILE=${WORKDIR}/containerd.pid
	CTR="${BIN}/ctr-enc -a ${CONTAINERD_SOCKET}"
}

startContainerd() {
	cat <<_EOF_ >${CONFIG_TOML}
disable_plugins = ["cri"]
root = "${ROOTDIR}"
state = "${STATEDIR}"
[grpc]
  address = "${CONTAINERD_SOCKET}"
  uid = 0
  gid = 0

[stream_processors]
    [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
	accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
	returns = "application/vnd.oci.image.layer.v1.tar+gzip"
	path = "${BIN}/ctd-decoder"

    [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
	accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
	returns = "application/vnd.oci.image.layer.v1.tar"
	path = "${BIN}/ctd-decoder"
_EOF_
	mkdir -p ${ROOTDIR}
	mkdir -p ${STATEDIR}
	sudo bash -c "${CONTAINERD} -c ${CONFIG_TOML} &>${LOGFILE} & echo \$! > ${PIDFILE}; wait" &
	sleep 1
	CONTAINERD_PID="$(cat ${PIDFILE})"
	sudo kill -0 ${CONTAINERD_PID}
	if [ $? -ne 0 ]; then
		echo "Could not start containerd"
		cat ${CONFIG_TOML}
		cat ${LOGFILE}
		exit 1
	fi
	sudo chmod 777 ${CONTAINERD_SOCKET}
}

startContainerdLocalKeys() {
	LOCAL_KEYS_PATH="${WORKDIR}/keys"
	mkdir -p ${LOCAL_KEYS_PATH}
	cat <<_EOF_ >${CONFIG_TOML}
disable_plugins = ["cri"]
root = "${ROOTDIR}"
state = "${STATEDIR}"
[grpc]
  address = "${CONTAINERD_SOCKET}"
  uid = 0
  gid = 0

[stream_processors]
    [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
	accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
	returns = "application/vnd.oci.image.layer.v1.tar+gzip"
	path = "${BIN}/ctd-decoder"
	args = ["--decryption-keys-path", "${LOCAL_KEYS_PATH}"]

    [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
	accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
	returns = "application/vnd.oci.image.layer.v1.tar"
	path = "${BIN}/ctd-decoder"
	args = ["--decryption-keys-path", "${LOCAL_KEYS_PATH}"]
_EOF_
	mkdir -p ${ROOTDIR}
	mkdir -p ${STATEDIR}
	sudo bash -c "${CONTAINERD} -c ${CONFIG_TOML} &>${LOGFILE} & echo \$! > ${PIDFILE}; wait" &
	sleep 1
	CONTAINERD_PID="$(cat ${PIDFILE})"
	sudo kill -0 ${CONTAINERD_PID}
	if [ $? -ne 0 ]; then
		echo "Could not start containerd"
		cat ${CONFIG_TOML}
		cat ${LOGFILE}
		exit 1
	fi
	sudo chmod 777 ${CONTAINERD_SOCKET}
}

failExit() {
	local rc=$1
	local msg="$2"
	if [ $rc -ne 0 ]; then
		echo -e "Error: $msg" >&2
		echo >&2
		exit 1
	fi
}

pullImages() {
	if [ -z "$IMAGE_PULL_CREDS" ]; then
		echo "Note: Image pull credentials can be passed with env. variable IMAGE_PULL_CREDS=<username>:<password>"
	fi
	$CTR images rm --sync ${ALPINE_ENC} ${ALPINE_DEC} ${NGINX_ENC} ${NGINX_DEC} &>/dev/null
	$CTR images pull ${IMAGE_PULL_CREDS:+--user ${IMAGE_PULL_CREDS}} --all-platforms ${ALPINE} &>/dev/null
	failExit $? "Image pull failed on ${ALPINE}"

	$CTR images pull ${IMAGE_PULL_CREDS:+--user ${IMAGE_PULL_CREDS}} --platform linux/amd64 ${NGINX} &>/dev/null
	failExit $? "Image pull failed on ${NGINX}"

	LAYER_INFO_ALPINE="$($CTR images layerinfo ${ALPINE})"
	failExit $? "Image layerinfo on plain image failed"

	LAYER_INFO_NGINX="$($CTR images layerinfo ${NGINX})"
	failExit $? "Image layerinfo on plain image failed"
}

setupPGP() {
	GPGHOMEDIR=${WORKDIR}/gpg2

	if [ -z "$(type -P gpg2)" ]; then
		failExit 1 "Missing gpg2 executable."
	fi

	mkdir -p ${GPGHOMEDIR}
	failExit $? "Could not create GPG2 home directory"
	gpg2 --home ${GPGHOMEDIR} --import <(echo "${GPGTESTKEY1}" | base64 -d) &>/dev/null
	failExit $? "Could not import GPG2 test key 1"
	gpg2 --home ${GPGHOMEDIR} --import <(echo "${GPGTESTKEY2}" | base64 -d) &>/dev/null
	failExit $? "Could not import GPG2 test key 1"
}

testPGP() {
	setupPGP
	echo "Testing PGP type of encryption on ${NGINX}"

	# nginx has large layers that are worth testing
	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--platform linux/amd64 \
		--recipient pgp:testkey1@key.org \
		${NGINX} ${NGINX_ENC}
	failExit $? "Image encryption of ${NGINX} with PGP failed"

	LAYER_INFO_NGINX_ENC="$($CTR images layerinfo ${NGINX_ENC})"
	failExit $? "Image layerinfo on PGP encrypted image failed"

	diff <(echo "${LAYER_INFO_NGINX}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_NGINX_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on PGP encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_NGINX_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONpgp")
	failExit $? "Image layerinfo on PGP encrypted image shows unexpected encryption"

	$CTR images decrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		${NGINX_ENC} ${NGINX_DEC}
	failExit $? "Image decryption with PGP failed"

	LAYER_INFO_NGINX_DEC="$($CTR images layerinfo ${NGINX_DEC})"
	failExit $? "Image layerinfo on decrypted image failed (PGP)"

	diff <(echo "${LAYER_INFO_NGINX}") <(echo "${LAYER_INFO_NGINX_DEC}")
	failExit $? "Image layerinfos are different (PGP)"

	$CTR images rm --sync ${NGINX_DEC} ${NGINX_ENC} &>/dev/null

	echo "PASS: PGP Type of encryption on ${NGINX}"
	echo
	echo "Testing PGP Type of encryption on ${ALPINE}"

	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--recipient pgp:testkey1@key.org \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with PGP failed"

	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on PGP encrypted image failed"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on PGP encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONpgp")
	failExit $? "Image layerinfo on PGP encrypted image shows unexpected encryption"

	$CTR images decrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		${ALPINE_ENC} ${ALPINE_DEC}
	failExit $? "Image decryption with PGP failed"

	LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
	failExit $? "Image layerinfo on decrypted image failed (PGP)"

	diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
	failExit $? "Image layerinfos are different (PGP)"

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE} &>/dev/null

	echo "PASS: PGP Type of encryption"
	echo
	echo "Testing image export and import using ${ALPINE_ENC}"

	$CTR images export \
		--all-platforms \
		${WORKDIR}/${ALPINE_ENC_EXPORT_NAME} ${ALPINE_ENC}
	failExit $? "Could not export ${ALPINE_ENC}"

	# remove ${ALPINE} and ${ALPINE_ENC} to clear cached and so we need to decrypt
	$CTR images rm --sync ${ALPINE} ${ALPINE_ENC} &>/dev/null

	$CTR images import \
		--all-platforms \
		--base-name ${ALPINE_ENC_IMPORT_BASE} \
		${WORKDIR}/${ALPINE_ENC_EXPORT_NAME} &>/dev/null
	if [ $? -eq 0 ]; then
		failExit 1 "Import of encrypted image without passing PGP key should not have succeeded"
	fi

	MSG=$($CTR images import \
		--all-platforms \
		--base-name ${ALPINE_ENC_IMPORT_BASE} \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		${WORKDIR}/${ALPINE_ENC_EXPORT_NAME} 2>&1)
	failExit $? "Import of PGP encrypted image should have worked\n$MSG"

	LAYER_INFO_ALPINE_ENC_NEW="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on imported image failed (PGP)"

	diff <(echo "${LAYER_INFO_ALPINE_ENC_NEW}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on PGP encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC_NEW}") <(echo "${LAYER_INFO_ALPINE_ENC}")
	failExit $? "Image layerinfos are different (PGP)"

	# restore ${ALPINE}
	MSG=$($CTR images decrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		${ALPINE_ENC} ${ALPINE} 2>&1)
	failExit $? "Image decryption with PGP failed\n$MSG"

	LAYER_INFO_ALPINE_NEW="$($CTR images layerinfo ${ALPINE})"
	failExit $? "Image layerinfo on imported image failed (PGP)"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_NEW}" | gawk '{print $3}')
	failExit $? "Image layerinfo on plain ${ALPINE} image shows differences in architectures"

	echo "PASS: Export and import of PGP encrypted image"
	echo
	echo "Testing creation of container from encrypted image"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo $CTR container create ${ALPINE_ENC} testcontainer1 2>&1)
	if [ $? -eq 0 ]; then
		MSG=$($CTR container rm testcontainer1 2>&1)
		MSG=$($CTR snapshot rm testcontainer1 2>&1)
		failExit 1 "Should not have been able to create a container from encrypted image without passing keys"
	fi
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo bash -c "$CTR container create \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		${ALPINE_ENC} testcontainer1 2>&1")
	failExit $? "Should have been able to create a container from encrypted image when passing keys\n${MSG}"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)

	MSG=$(sudo bash -c "$CTR run \
		--rm \
		${ALPINE_ENC} testcontainer1 echo 'Hello world'" 2>&1)
	if [ $? -eq 0 ]; then
		MSG=$($CTR snapshot rm testcontainer1 2>&1)
		failExit 1 "Should not have been able to run a container from encrypted image without passing keys"
	fi
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo bash -c "$CTR run \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		--rm \
		${ALPINE_ENC} testcontainer1 echo 'Hello world'" 2>&1)
	failExit $? "Should have been able to run a container from encrypted image when passing keys\n${MSG}"

	echo "PASS: Creation of container from encrypted image"
	echo
	echo "Testing adding a PGP recipient"
	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--key <(echo "${GPGTESTKEY1}" | base64 -d) \
		--recipient pgp:testkey2@key.org ${ALPINE_ENC}
	failExit $? "Adding recipient to PGP encrypted image failed"

	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo -n ${ALPINE_ENC})"
	failExit $? "Image layerinfo on PGP encrypted image failed"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on PGP encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $6 $7}' | sort | uniq | tr -d '\n') \
		<(echo -n "0xbebc2c4b1c4ef646,0xbfb902bf9ff6f235RECIPIENTS")
	failExit $? "Image layerinfo on PGP encrypted image shows unexpected recipients"

	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo --gpg-homedir ${GPGHOMEDIR} --gpg-version 2 ${ALPINE_ENC})"
	failExit $? "Image layerinfo on PGP encrypted image failed"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $6 $7}' | sort | uniq | tr -d '\n') \
		<(echo -n "RECIPIENTStestkey1@key.org,testkey2@key.org")
	failExit $? "Image layerinfo on PGP encrypted image shows unexpected recipients"

	for privkey in ${GPGTESTKEY1} ${GPGTESTKEY2}; do
		$CTR images decrypt \
			--gpg-homedir ${GPGHOMEDIR} \
			--gpg-version 2 \
			--key <(echo "${privkey}" | base64 -d) \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with PGP failed"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (PGP)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (PGP)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "PGP Decryption worked."
	done

	echo "PASS: PGP Type of decryption after adding recipients"
	echo

	$CTR images rm --sync ${ALPINE_ENC} ${ALPINE_DEC} &>/dev/null
}

createJWEKeys() {
	local rc

	echo "Generating keys for JWE encryption"

	PRIVKEYPEM=${WORKDIR}/mykey.pem
	PRIVKEYDER=${WORKDIR}/mykey.der
	PRIVKEYPK8PEM=${WORKDIR}/mykeypk8.pem
	PRIVKEYPK8DER=${WORKDIR}/mykeypk8.der

	PUBKEYPEM=${WORKDIR}/mypubkey.pem
	PUBKEYDER=${WORKDIR}/mypubkey.der

	PRIVKEY2PEM=${WORKDIR}/mykey2.pem
	PUBKEY2PEM=${WORKDIR}/mypubkey2.pem

	PRIVKEY3PASSPEM=${WORKDIR}/mykey3pass.pem
	PRIVKEY3PASSWORD="1234"
	PUBKEY3PEM=${WORKDIR}/pubkey3.pem

	PRIVKEYJWK=${WORKDIR}/mykey.jwk
	PUBKEYJWK=${WORKDIR}/mypubkey.jwk

	ECPRIVKEYDER=${WORKDIR}/myeckey.der
	ECPUBKEYDER=${WORKDIR}/myecpubkey.der

	MSG="$(openssl genrsa -out ${PRIVKEYPEM} 2>&1)"
	failExit $? "Could not generate private key\n$MSG"

	MSG="$(openssl rsa -inform pem -outform der -in ${PRIVKEYPEM} -out ${PRIVKEYDER} 2>&1)"
	failExit $? "Could not convert private key to DER format\n$MSG"

	MSG="$(openssl pkcs8 -topk8 -nocrypt -inform pem -outform pem -in ${PRIVKEYPEM} -out ${PRIVKEYPK8PEM} 2>&1)"
	failExit $? "Could not convert private key to PKCS8 PEM format\n$MSG"

	MSG="$(openssl pkcs8 -topk8 -nocrypt -inform pem -outform der -in ${PRIVKEYPEM} -out ${PRIVKEYPK8DER} 2>&1)"
	failExit $? "Could not convert private key to PKCS8 DER format\n$MSG"

	MSG="$(openssl rsa -inform pem -outform pem -pubout -in ${PRIVKEYPEM} -out ${PUBKEYPEM} 2>&1)"
	failExit $? "Could not write public key in PEM format\n$MSG"

	MSG="$(openssl rsa -inform pem -outform der -pubout -in ${PRIVKEYPEM} -out ${PUBKEYDER} 2>&1)"
	failExit $? "Could not write public key in PEM format\n$MSG"

	MSG="$(openssl genrsa -out ${PRIVKEY2PEM} 2>&1)"
	failExit $? "Could not generate 2nd private key\n$MSG"

	MSG="$(openssl rsa -inform pem -outform pem -pubout -in ${PRIVKEY2PEM} -out ${PUBKEY2PEM} 2>&1)"
	failExit $? "Could not write 2nd public key in PEM format\n$MSG"

	MSG="$(openssl genrsa -aes256 -passout pass:${PRIVKEY3PASSWORD} -out ${PRIVKEY3PASSPEM} 2>&1)"
	failExit $? "Could not generate 3rd private key\n$MSG"

	MSG="$(openssl rsa -inform pem -outform pem -passin pass:${PRIVKEY3PASSWORD} -pubout -in ${PRIVKEY3PASSPEM} -out ${PUBKEY3PEM} 2>&1)"
	failExit $? "Could not write 3rd public key in PEM format\n$MSG"

	MSG="$(openssl ecparam -genkey -out ${ECPRIVKEYDER} -outform der -name secp521r1 2>&1)"
	failExit $? "Could not generate EC private key\n$MSG"

	MSG="$(openssl ec -in ${ECPRIVKEYDER} -inform der -pubout -outform der -out ${ECPUBKEYDER} 2>&1)"
	rc=$?
	# openssl may not have been able to read the EC key
	if [[ $MSG =~ "unable to load Key" ]]; then
		echo "OpenSSL cannot deal with DER formatted EC keys; cheating by using an RSA key"
		# we cheat a bit in this case
		cp ${PRIVKEYDER} ${ECPRIVKEYDER}
		cp ${PUBKEYDER} ${ECPUBKEYDER}
		rc=0
	fi
	failExit $rc "Could not write EC public key in DER format\n$MSG"

	echo "${JWKTESTKEY1}" >${PRIVKEYJWK}
	echo "${JWKTESTPUBKEY1}" >${PUBKEYJWK}
}

testJWE() {
	createJWEKeys
	echo "Testing JWE type of encryption"

	for recipient in jwe:${PUBKEYDER} jwe:${PUBKEYPEM}; do

		$CTR images encrypt \
			--recipient ${recipient} \
			${ALPINE} ${ALPINE_ENC}
		failExit $? "Image encryption with JWE failed; public key: ${recipient}"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on JWE encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on JWE encrypted image shows differences in architectures"

		diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
			<(echo -n "ENCRYPTIONjwe")
		failExit $? "Image layerinfo on JWE encrypted image shows unexpected encryption"

		for privkey in ${PRIVKEYPEM} ${PRIVKEYDER} ${PRIVKEYPK8PEM} ${PRIVKEYPK8DER}; do
			$CTR images decrypt \
				--key ${privkey} \
				${ALPINE_ENC} ${ALPINE_DEC}
			failExit $? "Image decryption with JWE failed: private key: ${privkey}"

			LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
			failExit $? "Image layerinfo on decrypted image failed (JWE)"

			diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
			failExit $? "Image layerinfos are different (JWE)"

			$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
			echo "Decryption with ${privkey} worked."
		done
		$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
		echo "Encryption with ${recipient} worked"
	done

	$CTR images rm --sync ${ALPINE_DEC} &>/dev/null

	echo "PASS: JWE Type of encryption"
	echo

	echo "Testing adding a JWE recipient"
	$CTR images encrypt \
		--recipient ${recipient} \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with JWE failed; public key: ${recipient}"

	$CTR images encrypt \
		--key ${PRIVKEYPEM} \
		--recipient jwe:${PUBKEY2PEM} \
		--recipient jwe:${PUBKEY3PEM} \
		--recipient jwe:${ECPUBKEYDER} \
		${ALPINE_ENC}
	failExit $? "Adding recipient to JWE encrypted image failed"

	for privkey in ${PRIVKEYPEM} ${PRIVKEY2PEM} ${PRIVKEY3PASSPEM} ${ECPRIVKEYDER}; do
		local key=${privkey}
		if [ "${privkey}" == "${PRIVKEY3PASSPEM}" ]; then
			key=${privkey}:pass=${PRIVKEY3PASSWORD}
		fi
		$CTR images decrypt \
			--key ${key} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with JWE failed: private key: ${privkey}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (JWE)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (JWE)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "Decryption with ${privkey} worked."
	done

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE_ENC} &>/dev/null

	echo "PASS: JWE Type of decryption after adding recipients"
	echo
	echo "Testing JWE encryption with a JWK"

	# The JWK needs a separate test since it's a different key than the other ones
	for recipient in jwe:${PUBKEYJWK}; do
		$CTR images encrypt \
			--recipient ${recipient} \
			${ALPINE} ${ALPINE_ENC}
		failExit $? "Image encryption with JWE failed; public key: ${recipient}"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on JWE encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on JWE encrypted image shows differences in architectures"

		diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
			<(echo -n "ENCRYPTIONjwe")
		failExit $? "Image layerinfo on JWE encrypted image shows unexpected encryption"

		for privkey in ${PRIVKEYJWK}; do
			$CTR images decrypt \
				--key ${privkey} \
				${ALPINE_ENC} ${ALPINE_DEC}
			failExit $? "Image decryption with JWE failed: private key: ${privkey}"

			LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
			failExit $? "Image layerinfo on decrypted image failed (JWE)"

			diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
			failExit $? "Image layerinfos are different (JWE)"

			$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
			echo "Decryption with ${privkey} worked."
		done
		$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
		echo "Encryption with ${recipient} worked"
	done

	echo "PASS: JWE encryption with a JWK"

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE_ENC} &>/dev/null
}

testLocalKeys() {
	createJWEKeys
	setupPKCS11

	echo "Testing JWE and PKCS11 type of encryption with local unpack keys"

	# Remove original images
	$CTR images rm --sync ${ALPINE_ENC} ${ALPINE_DEC} ${NGINX_ENC} ${NGINX_DEC} &>/dev/null

	local recipient1=jwe:${PUBKEYPEM}
	local recipient2=pkcs11:${SOFTHSM_KEY}
	$CTR images encrypt \
		--recipient ${recipient1} \
		--recipient ${recipient2} \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with JWE and PKCS11 failed"

	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on JWE encrypted image failed; public key: ${recipient}"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on JWE encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONjwe,pkcs11")
	failExit $? "Image layerinfo on JWE encrypted image shows unexpected encryption"

	# Remove snapshots to force the decryption with unpacker
	for i in $($CTR snapshots ls | tail -n +2 | awk '{print $1}'); do
		MSG=$($CTR snapshots rm $i 2>&1)
	done

	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo $CTR container create ${ALPINE_ENC} testcontainer1 2>&1)
	if [ $? -eq 0 ]; then
		MSG=$($CTR container rm testcontainer1 2>&1)
		MSG=$($CTR snapshot rm testcontainer1 2>&1)
		failExit 1 "Should not have been able to create a container from encrypted image without local keys existing"
	fi
	MSG=$($CTR snapshot rm testcontainer1 2>&1)

	for privkey in ${PRIVKEYPEM} ${ECPRIVKEYDER}; do
		cp $privkey ${LOCAL_KEYS_PATH}/.
	done

	echo "Testing creation of container from encrypted image with local keys (JWE)"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo $CTR container create ${ALPINE_ENC} --skip-decrypt-auth --key ${PRIVKEY2PEM} testcontainer1 2>&1)

	failExit $? "Should have been able to create a container from encrypted image when local keys exists (JWE)\n${MSG}"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)

	rm -f ${LOCAL_KEYS_PATH}/*

	# now test with the pkcs11 key
	for privkey in ${SOFTHSM_KEY}; do
		cp $privkey ${LOCAL_KEYS_PATH}/.
	done

	echo "Testing creation of container from encrypted image with local keys (PKCS11)"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)
	MSG=$(sudo $CTR container create ${ALPINE_ENC} --skip-decrypt-auth --key ${PRIVKEY2PEM} testcontainer1 2>&1)

	failExit $? "Should have been able to create a container from encrypted image when local keys exists (PKCS11)\n${MSG}"
	MSG=$($CTR container rm testcontainer1 2>&1)
	MSG=$($CTR snapshot rm testcontainer1 2>&1)

	$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
	echo "Encryption with ${recipient1} and ${recipient2} and decrypting with local unpack keys worked"

	echo "PASS: JWE and PKCS11 type of encryption with local unpack keys"
	echo
}

setupPKCS7() {
	echo "Generating certs for PKCS7 encryption"

	CACERT=${WORKDIR}/cacert.pem
	CAKEY=${WORKDIR}/cacertkey.pem
	CLIENTCERT=${WORKDIR}/clientcert.pem
	CLIENTCERTKEY=${WORKDIR}/clientcertkey.pem
	CLIENTCERTCSR=${WORKDIR}/clientcert.csr

	CLIENT2CERT=${WORKDIR}/client2cert.pem
	CLIENT2CERTKEY=${WORKDIR}/client2certkey.pem
	CLIENT2CERTCSR=${WORKDIR}/client2cert.csr

	local CFG="
[req]
distinguished_name = dn
[dn]
[ext]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:TRUE
"
	MSG="$(openssl req -config <(echo "${CFG}") -newkey rsa:2048 \
		-x509 -extensions ext -days 365 -nodes -keyout ${CAKEY} -out ${CACERT} \
		-subj '/CN=foo/' 2>&1)"
	failExit $? "Could not create root CA's certificate\n${MSG}"

	MSG="$(openssl genrsa -out ${CLIENTCERTKEY} 2048 2>&1)"
	failExit $? "Could not create client key\n$MSG"
	MSG="$(openssl req -new -key ${CLIENTCERTKEY} -out ${CLIENTCERTCSR} -subj '/CN=bar/' 2>&1)"
	failExit $? "Could not create client ertificate signing request\n$MSG"
	MSG="$(openssl x509 -req -in ${CLIENTCERTCSR} -CA ${CACERT} -CAkey ${CAKEY} -CAcreateserial \
		-out ${CLIENTCERT} -days 10 -sha256 2>&1)"
	failExit $? "Could not create client certificate\n$MSG"

	MSG="$(openssl genrsa -out ${CLIENT2CERTKEY} 2048 2>&1)"
	failExit $? "Could not create client2 key\n$MSG"
	MSG="$(openssl req -new -key ${CLIENT2CERTKEY} -out ${CLIENT2CERTCSR} -subj '/CN=bar/' 2>&1)"
	failExit $? "Could not create client2 certificate signing request\n$MSG"
	MSG="$(openssl x509 -req -in ${CLIENT2CERTCSR} -CA ${CACERT} -CAkey ${CAKEY} -CAcreateserial \
		-out ${CLIENT2CERT} -days 10 -sha256 2>&1)"
	failExit $? "Could not create client2 certificate\n$MSG"
}

testPKCS7() {
	setupPKCS7

	echo "Testing PKCS7 type of encryption"

	for recipient in pkcs7:${CLIENTCERT}; do
		$CTR images encrypt \
			--recipient ${recipient} \
			${ALPINE} ${ALPINE_ENC}
		failExit $? "Image encryption with PKCS7 failed; public key: ${recipient}"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on PKCS7 encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on PKCS7 encrypted image shows differences in architectures"

		diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
			<(echo -n "ENCRYPTIONpkcs7")
		failExit $? "Image layerinfo on PKCS7 encrypted image shows unexpected encryption"

		for privKeyAndRecipient in "${CLIENTCERTKEY}:${CLIENTCERT}"; do
			privkey="$(echo ${privKeyAndRecipient} | cut -d ":" -f1)"
			recp="$(echo ${privKeyAndRecipient} | cut -d ":" -f2)"
			$CTR images decrypt \
				--dec-recipient ${recipient} \
				--key ${privkey} \
				${ALPINE_ENC} ${ALPINE_DEC}
			failExit $? "Image decryption with PKCS7 failed: private key: ${privkey}"

			LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
			failExit $? "Image layerinfo on decrypted image failed (PKCS7)"

			diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
			failExit $? "Image layerinfos are different (PKCS7)"

			$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
			echo "Decryption with ${privkey} worked."
		done
		$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
		echo "Encryption with ${recipient} worked"
	done

	echo "PASS: PKCS7 Type of encryption"
	echo

	echo "Testing adding a PKCS7 recipient"
	$CTR images encrypt \
		--recipient pkcs7:${CLIENTCERT} \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with PKCS7 failed; public key: ${recipient}"

	$CTR images encrypt \
		--key ${CLIENTCERTKEY} \
		--dec-recipient pkcs7:${CLIENTCERT} \
		--recipient pkcs7:${CLIENT2CERT} \
		${ALPINE_ENC}
	failExit $? "Adding recipient to PKCS7 encrypted image failed"

	for privKeyAndRecipient in "${CLIENTCERTKEY}:${CLIENTCERT}" "${CLIENT2CERTKEY}:${CLIENT2CERT}"; do
		privkey="$(echo ${privKeyAndRecipient} | cut -d ":" -f1)"
		recp="$(echo ${privKeyAndRecipient} | cut -d ":" -f2)"
		$CTR images decrypt \
			--key ${privkey} \
			--dec-recipient pkcs7:${recp} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with PKCS7 failed: private key: ${privkey}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (PKCS7)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (PKCS7)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "Decryption with ${privkey} worked."
	done

	echo "PASS: PKCS7 Type of decryption after adding recipients"
	echo

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE_ENC} &>/dev/null
}

setupPKCS11() {
	echo "Generating softhsm key for PKCS11 encryption"

	local output

	# Env. variable for softhsm_setup
	export SOFTHSM_SETUP_CONFIGDIR=${WORKDIR}
	# Env. variable for ctr-enc
	export OCICRYPT_CONFIG=internal
	SOFTHSM_KEY=${WORKDIR}/softhsm_key.yaml

	output=$(${SOFTHSM_SETUP} setup 2>&1)
	failExit $? "'softhsm_setup setup' failed: ${output}"
	keyuri=$(echo "${output}" | cut -d " " -f2)
	cat <<_EOF_ >${SOFTHSM_KEY}
pkcs11:
  uri: ${keyuri}
module:
  env:
    SOFTHSM2_CONF: ${SOFTHSM_SETUP_CONFIGDIR}/softhsm2.conf
_EOF_

	# Note: Need to set OCICRYPT_OAEP_HASHALG=sha1 to be able to decrypt after using the PEM key!
	SOFTHSM_KEY_PEM=${WORKDIR}/softhsm_key.pem
	${SOFTHSM_SETUP} getpubkey > ${SOFTHSM_KEY_PEM}
	failExit $? "'softhsm_setup getpubkey' failed"
}

testPKCS11() {
	setupPKCS11

	echo "Testing PKCS11 type of encryption"

	# Env. variable needed for encryption with SOFTHSM_KEY_PEM
	export OCICRYPT_OAEP_HASHALG=sha1

	for recipient in pkcs11:${SOFTHSM_KEY} pkcs11:${SOFTHSM_KEY_PEM}; do
		$CTR images encrypt \
			--recipient ${recipient} \
			${ALPINE} ${ALPINE_ENC}
		failExit $? "Image encryption with PKCS11 failed; public key: ${recipient}"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on PKCS11 encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on PKCS11 encrypted image shows differences in architectures"

		diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
			<(echo -n "ENCRYPTIONpkcs11")
		failExit $? "Image layerinfo on PKCS11 encrypted image shows unexpected encryption"

		for privkey in ${SOFTHSM_KEY}; do
			$CTR images decrypt \
				--key ${privkey} \
				${ALPINE_ENC} ${ALPINE_DEC}
			failExit $? "Image decryption with PKCS11 failed: private key: ${privkey}"

			LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
			failExit $? "Image layerinfo on decrypted image failed (PKCS11)"

			diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
			failExit $? "Image layerinfos are different (PKCS11)"

			$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
			echo "Decryption with ${privkey} worked."
		done
		$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
		echo "Encryption with ${recipient} worked"
	done

	$CTR images rm --sync ${ALPINE_DEC} &>/dev/null

	echo "PASS: PKCS11 Type of encryption"
	echo
}

testPGPandJWEandPKCS7andPKCS11andKeyprovider() {
	local ctr

	createJWEKeys
	setupPGP
	setupPKCS7
	setupPKCS11
	setupKeyprovider

	# Env. variable needed for encryption with SOFTHSM_KEY_PEM
	export OCICRYPT_OAEP_HASHALG=sha1

	echo "Testing large recipient list"
	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--recipient pgp:testkey1@key.org \
		--recipient pgp:testkey2@key.org \
		--recipient jwe:${PUBKEYPEM} \
		--recipient jwe:${PUBKEY2PEM} \
		--recipient pkcs7:${CLIENTCERT} \
		--recipient pkcs7:${CLIENT2CERT} \
		--recipient pkcs11:${SOFTHSM_KEY} \
		--recipient pkcs11:${SOFTHSM_KEY_PEM} \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption to many different recipients failed"
	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on multi-recipient encrypted image failed; public key: ${recipient}"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on multi-recipient encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONjwe,pgp,pkcs11,pkcs7")

	$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
	echo "Encryption to multiple different types of recipients worked."

	echo "Testing adding first PGP and then JWE and PKCS7 and PKCS11 recipients"
	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--recipient pgp:testkey1@key.org \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with PGP failed; recipient: testkey1@key.org"

	ctr=0
	for recipient in jwe:${PUBKEYPEM} \
			pgp:testkey2@key.org \
			jwe:${PUBKEY2PEM} \
			pkcs7:${CLIENTCERT} pkcs7:${CLIENT2CERT} \
			pkcs11:${SOFTHSM_KEY} pkcs11:${SOFTHSM_KEY_PEM} \
			${KEYPROVIDER:+provider:testkeyprovider:123}; do
		$CTR images encrypt \
			--gpg-homedir ${GPGHOMEDIR} \
			--gpg-version 2 \
			--recipient ${recipient} \
			--key <(echo "${GPGTESTKEY1}" | base64 -d) \
			${ALPINE_ENC}
		failExit $? "Adding ${recipient} failed"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on multi-recipient encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on multi-recipient encrypted image shows differences in architectures"

		if [ $ctr -lt 3 ]; then
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp")
		elif [ $ctr -lt 5 ]; then
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp,pkcs7")
		elif [ $ctr -lt 7 ]; then
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp,pkcs11,pkcs7")
		else
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp,pkcs11,pkcs7,provider.testkeyprovider")
		fi
		failExit $? "Image layerinfo on multi-recipient-encrypted image shows unexpected encryption (ctr=$ctr)"
		ctr=$((ctr + 1))
	done

	# everyone must be able to decrypt it -- first JWE ...
	for privkey in ${PRIVKEYPEM} ${PRIVKEY2PEM}; do
		$CTR images decrypt \
			--key ${privkey} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with JWE failed: private key: ${privkey}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (JWE)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (JWE)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "JWE Decryption with ${privkey} worked."
	done

	# ... then pgp
	for privkey in ${GPGTESTKEY1} ${GPGTESTKEY2}; do
		$CTR images decrypt \
			--gpg-homedir ${GPGHOMEDIR} \
			--gpg-version 2 \
			--key <(echo "${privkey}" | base64 -d) \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with PGP failed"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (PGP)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (PGP)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "PGP Decryption worked."
	done

	# and then pkcs7
	for privKeyAndRecipient in "${CLIENTCERTKEY}:${CLIENTCERT}" "${CLIENT2CERTKEY}:${CLIENT2CERT}"; do
		privkey="$(echo ${privKeyAndRecipient} | cut -d ":" -f1)"
		recp="$(echo ${privKeyAndRecipient} | cut -d ":" -f2)"
		$CTR images decrypt \
			--key ${privkey} \
			--dec-recipient pkcs7:${recp} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with PKCS7 failed: private key: ${privkey}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (PKCS7)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (PKCS7)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "PKCS7 decryption with ${privkey} worked."
	done

	# and finally pkcs11
	for privkey in ${SOFTHSM_KEY}; do
		$CTR images decrypt \
			--key ${privkey} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with PKCS11 failed: private key: ${privkey}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (PKCS11)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (PKCS11)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "PKCS11 Decryption with ${privkey} worked."
	done

	# and if KEYPROVIDER is set, also try provider:
	for keyprovider in ${KEYPROVIDER:+provider:testkeyprovider:123}; do
		$CTR images decrypt \
			--key ${keyprovider} \
			${ALPINE_ENC} ${ALPINE_DEC}
		failExit $? "Image decryption with keyprovider failed: private key: ${keyprovider}"

		LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
		failExit $? "Image layerinfo on decrypted image failed (keyprovider)"

		diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
		failExit $? "Image layerinfos are different (keyprovider)"

		$CTR images rm --sync ${ALPINE_DEC} &>/dev/null
		echo "keyprovider Decryption with ${keyprovider} worked."
	done

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE_ENC} &>/dev/null

	echo "Testing adding first JWE and then PGP and PKCS7 and PKCS11 recipients"
	$CTR images encrypt \
		--recipient jwe:${PUBKEYPEM} \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with JWE failed; public key: ${recipient}"

	ctr=0
	for recipient in pgp:testkey1@key.org pgp:testkey2@key.org \
			jwe:${PUBKEY2PEM} \
			pkcs7:${CLIENTCERT} pkcs7:${CLIENT2CERT} \
			pkcs11:${SOFTHSM_KEY} pkcs11:${SOFTHSM_KEY_PEM}; do
		$CTR images encrypt \
			--gpg-homedir ${GPGHOMEDIR} \
			--gpg-version 2 \
			--recipient ${recipient} \
			--key ${PRIVKEYPEM} \
			${ALPINE_ENC}
		failExit $? "Adding ${recipient} failed"

		LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
		failExit $? "Image layerinfo on JWE encrypted image failed; public key: ${recipient}"

		diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
			<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
		failExit $? "Image layerinfo on JWE encrypted image shows differences in architectures"

		if [ $ctr -lt 3 ]; then
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp")
		elif [ $ctr -lt 5 ]; then
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp,pkcs7")
		else
			diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
				<(echo -n "ENCRYPTIONjwe,pgp,pkcs11,pkcs7")
		fi
		failExit $? "Image layerinfo on JWE encrypted image shows unexpected encryption"
		ctr=$((ctr + 1))
	done

	echo "PASS: Test with ${KEYPROVIDER:+keyprovider, }JWE, PGP, PKCS7, and PKCS11 recipients"
	echo

	$CTR images rm --sync ${ALPINE_DEC} ${ALPINE_ENC} &>/dev/null
}

setupKeyprovider() {
	if [ -z "${KEYPROVIDER}" ]; then
		return
	fi
	export OCICRYPT_KEYPROVIDER_CONFIG=${WORKDIR}/ocicrypt-keyprovider.conf

	cat <<_EOF_ >${OCICRYPT_KEYPROVIDER_CONFIG}
{
  "key-providers": {
    "testkeyprovider": {
      "cmd": {
        "path": "${KEYPROVIDER}",
        "args": []
      }
    }
  }
}
_EOF_
}

testKeyproviderInvalidPath() {
    export OCICRYPT_KEYPROVIDER_CONFIG=/path/to/nowhere
    testJWE
}

testKeyprovider() {
	if [ -z "${KEYPROVIDER}" ]; then
		echo "Skipping keyprovider test; require KEYPROVIDER to point to executable"
		return 0
	fi

	createJWEKeys
	setupPGP
	setupPKCS7
	setupPKCS11
	setupKeyprovider

	echo "Testing keyprovider using '${KEYPROVIDER}'"

	echo "Testing large recpient list"

	$CTR images encrypt \
		--recipient provider:testkeyprovider:foobar \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption with keyprovider failed"

	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on keyprovider-encrypted image failed"
	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on keyprovider encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONprovider.testkeyprovider")
	failExit $? "Image layerinfo on keyprovider encrypted image shows unexpected encryption"

	MSG=$(sudo $CTR container create ${ALPINE_ENC} --skip-decrypt-auth --key provider:testkeyprovider:xyz testcontainer1 2>&1)

	failExit $? "Should have been able to create a container from encrypted (keyprovider)\n${MSG}"

	$CTR images decrypt \
		--key provider:testkeyprovider:123 \
		${ALPINE_ENC} ${ALPINE_DEC}
	failExit $? "Image decryption with keyprovider failed"

	LAYER_INFO_ALPINE_DEC="$($CTR images layerinfo ${ALPINE_DEC})"
	failExit $? "Image layerinfo on decrypted image failed (keyprovider)"

	diff <(echo "${LAYER_INFO_ALPINE}") <(echo "${LAYER_INFO_ALPINE_DEC}")
	failExit $? "Image layerinfos are different (keyprovider)"

	$CTR images rm --sync ${ALPINE_ENC} ${ALPINE_DEC} &>/dev/null
	echo "Decryption with keyprovider worked."

	echo "PASS: keyprovider type of encryption"
	echo

	createJWEKeys
	setupPGP
	setupPKCS7
	setupPKCS11

	echo "Testing large recpient list"
	$CTR images encrypt \
		--gpg-homedir ${GPGHOMEDIR} \
		--gpg-version 2 \
		--recipient pgp:testkey1@key.org \
		--recipient pgp:testkey2@key.org \
		--recipient jwe:${PUBKEYPEM} \
		--recipient jwe:${PUBKEY2PEM} \
		--recipient pkcs7:${CLIENTCERT} \
		--recipient pkcs7:${CLIENT2CERT} \
		--recipient pkcs11:${SOFTHSM_KEY} \
		--recipient pkcs11:${SOFTHSM_KEY_PEM} \
		--recipient provider:testkeyprovider:foobar \
		${ALPINE} ${ALPINE_ENC}
	failExit $? "Image encryption to many different recipients failed"
	LAYER_INFO_ALPINE_ENC="$($CTR images layerinfo ${ALPINE_ENC})"
	failExit $? "Image layerinfo on multi-recipient encrypted image failed; public key: ${recipient}"

	diff <(echo "${LAYER_INFO_ALPINE}" | gawk '{print $3}') \
		<(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $3}')
	failExit $? "Image layerinfo on multi-recipient encrypted image shows differences in architectures"

	diff <(echo "${LAYER_INFO_ALPINE_ENC}" | gawk '{print $5}' | sort | uniq | tr -d '\n') \
		<(echo -n "ENCRYPTIONjwe,pgp,pkcs11,pkcs7,provider.testkeyprovider")

	$CTR images rm --sync ${ALPINE_ENC} &>/dev/null
	echo "Encryption to multiple different types of recipients worked."
}


# Test containerd with flow where keys are passed in via containerd API
setup
startContainerd
pullImages
testPGP
testJWE
testPKCS7
testPKCS11
testPGPandJWEandPKCS7andPKCS11andKeyprovider
testKeyprovider
testKeyproviderInvalidPath
cleanup

# Test containerd with flow where keys are in local directory
echo "Testing with containerd + local keys files"
echo
setup
startContainerdLocalKeys
pullImages
testLocalKeys
cleanup

exit 0
