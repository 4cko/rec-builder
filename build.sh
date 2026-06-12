#!/bin/bash
set -e
set -o pipefail

export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"

mkdir -p ~/bin

if ! command -v repo >/dev/null 2>&1; then
    curl -fsSL \
    https://storage.googleapis.com/git-repo-downloads/repo \
    -o ~/bin/repo

    chmod +x ~/bin/repo
fi

export PATH="$HOME/bin:$PATH"

sudo apt update

sudo apt install -y \
git git-lfs curl wget unzip zip rsync bc \
build-essential flex bison gperf \
gcc-multilib g++-multilib libc6-dev-i386 \
lib32z1-dev zlib1g-dev \
libncurses-dev \
libxml2-utils xsltproc \
libssl-dev libelf-dev \
ccache python3

mkdir -p ~/twrp
cd ~/twrp

repo init \
-u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp \
-b twrp-12.1

repo sync -j"$(nproc)" --force-sync --no-clone-bundle

mkdir -p device/xiaomi

git clone \
https://github.com/4cko/android_device_xiaomi_moon.git \
device/xiaomi/moon

source build/envsetup.sh

lunch twrp_moon-eng || lunch omni_moon-eng

mka recoveryimage 2>&1 | tee build.log
