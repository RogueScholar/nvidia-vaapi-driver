#!/usr/bin/env bash
set -euo pipefail
shopt -s xpg_echo

typeset base_url distro_name keyring llvm_apt llvm_stable llvm_ver signing_key \
  suite uri
typeset -gx DEBIAN_FRONTEND="noninteractive"

base_url="http://apt.llvm.org"
keyring="/etc/apt/keyrings/llvm.gpg"
llvm_stable="18"
signing_key="${base_url}/llvm-snapshot.gpg.key"

sudo apt update || return 0
sudo apt --yes install gpg lsb-release software-properties-common wget

case "${DISTRO}" in
  *ubuntu*20.04*)
    distro_name="focal"
    ;;
  *ubuntu*22.04*)
    distro_name="jammy"
    ;;
  *ubuntu*24.04* | *ubuntu*latest)
    distro_name="noble"
    ;;
  *ubuntu*24.10*)
    distro_name="oracular"
    ;;
  *ubuntu*25.04*)
    distro_name="plucky"
    ;;
  *)
    distro_name="$(lsb_release -cs)"
esac

case "${1:-$llvm_stable}" in
  18)
    llvm_ver="-18"
    ;;
  19)
    llvm_ver="-19"
    ;;
  20)
    llvm_ver=""
    ;;
esac

uri="${base_url}/${distro_name}"
suite="llvm-toolchain-${distro_name}${llvm_ver}"
llvm_apt="$(cat <<-EOF
	Enabled: yes
	Types: deb deb-src
	Architectures: amd64
	Signed-By: "${keyring}"
	URIs: "${uri}"
	Suites: "${suite}"
	Components: main
	EOF
)"

for dir in keyrings sources.list.d; do
  [[ -d "/etc/apt/${dir}" ]] || sudo mkdir -pv "/etc/apt/${dir}"
done

wget -qO- "${signing_key}" | sudo apt-key --keyring "${keyring}" add -

echo "${llvm_apt}" | sudo tee /etc/apt/sources.list.d/llvm.sources

sudo apt update || return 0
sudo apt --yes install "clang${llvm_ver}" "lld${llvm_ver}" "llvm${llvm_ver}"
sudo apt --yes full-upgrade

exit 0
