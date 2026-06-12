#!/usr/bin/env bash

set -e
set -o pipefail

# =====================================================
# CONFIG
# =====================================================

export DEVICE=moon
export DT_REPO="https://github.com/4cko/android_device_xiaomi_moon.git"

export MANIFEST_URL="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp"
export MANIFEST_BRANCH="twrp-12.1"

export WORKDIR="$HOME/twrp"
export LOGDIR="$HOME/build_logs"

# =====================================================
# INSTALL DEPENDENCIES
# =====================================================

echo "========================================"
echo "Installing dependencies"
echo "========================================"

sudo dpkg --add-architecture i386 || true

sudo apt update

sudo apt install -y \
git git-lfs curl wget rsync bc \
build-essential flex bison gperf \
zip unzip \
gcc-multilib g++-multilib \
libc6-dev-i386 \
lib32z1-dev \
zlib1g-dev \
libncurses-dev \
libssl-dev \
libelf-dev \
libxml2-utils \
xsltproc \
ccache \
python3 \
python-is-python3

# =====================================================
# INSTALL REPO TOOL
# =====================================================

echo "========================================"
echo "Installing repo"
echo "========================================"

mkdir -p "$HOME/bin"

curl -fsSL \
https://storage.googleapis.com/git-repo-downloads/repo \
-o "$HOME/bin/repo"

chmod +x "$HOME/bin/repo"

export PATH="$HOME/bin:$PATH"

echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# =====================================================
# CCACHE
# =====================================================

echo "========================================"
echo "Configuring ccache"
echo "========================================"

export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)

ccache -M 20G || true

# =====================================================
# INIT SOURCE
# =====================================================

echo "========================================"
echo "Initializing source"
echo "========================================"

mkdir -p "$WORKDIR"

cd "$WORKDIR"

if [ ! -d ".repo" ]; then
    repo init \
        -u "$MANIFEST_URL" \
        -b "$MANIFEST_BRANCH"
fi

repo sync \
    -j"$(nproc --all)" \
    --force-sync \
    --no-clone-bundle \
    --no-tags

# =====================================================
# DEVICE TREE
# =====================================================

echo "========================================"
echo "Cloning device tree"
echo "========================================"

rm -rf device/xiaomi/$DEVICE

mkdir -p device/xiaomi

git clone \
    "$DT_REPO" \
    device/xiaomi/$DEVICE

# =====================================================
# OPTIONAL DEPENDENCIES
# =====================================================

if [ -f "device/xiaomi/$DEVICE/twrp.dependencies" ]; then
    echo "Found twrp.dependencies"
    cat "device/xiaomi/$DEVICE/twrp.dependencies"
fi

if [ -f "device/xiaomi/$DEVICE/roomservice.xml" ]; then
    echo "Found roomservice.xml"
fi

# =====================================================
# BUILD
# =====================================================

echo "========================================"
echo "Starting build"
echo "========================================"

mkdir -p "$LOGDIR"

source build/envsetup.sh

if lunch twrp_${DEVICE}-eng; then
    echo "Using twrp_${DEVICE}-eng"
elif lunch omni_${DEVICE}-eng; then
    echo "Using omni_${DEVICE}-eng"
else
    echo "No valid lunch target found"
    exit 1
fi

mka recoveryimage 2>&1 | tee "$LOGDIR/build.log"

# =====================================================
# RESULT
# =====================================================

echo
echo "========================================"
echo "Build Finished"
echo "========================================"

find out/target/product -name "*.img" 2>/dev/null

echo
echo "Log:"
echo "$LOGDIR/build.log"#!/bin/bash
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
