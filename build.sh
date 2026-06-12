#!/bin/bash
set -e
set -o pipefail

# ===== CONFIG =====
TWRP_MANIFEST="https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp"
TWRP_BRANCH="twrp-12.1"
DEVICE_TREE="https://github.com/4cko/android_device_xiaomi_moon.git"
DEVICE_CODENAME="moon"
WORKDIR="$HOME/twrp"
LOGDIR="$PWD/build_logs"

# ===== STEP 1: Install dependencies =====
echo "Installing dependencies..."
sudo apt update
sudo apt install -y git curl unzip wget flex bison build-essential \
zip zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
lib32ncurses5-dev lib32z1-dev ccache libxml2-utils python3

# Optional: GUI libs for TWRP (if needed)
sudo apt install -y libgl1-mesa-dev libx11-dev x11proto-core-dev xsltproc

# ===== STEP 2: Install repo tool =====
echo "Installing repo tool..."
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# ===== STEP 3: Initialize TWRP repo =====
echo "Initializing TWRP repo..."
mkdir -p $WORKDIR
cd $WORKDIR
repo init -u $TWRP_MANIFEST -b $TWRP_BRANCH
repo sync --force-sync --no-clone-bundle --quiet

# ===== STEP 4: Clone device tree =====
echo "Cloning device tree..."
mkdir -p $WORKDIR/device/xiaomi
git clone $DEVICE_TREE $WORKDIR/device/xiaomi/$DEVICE_CODENAME

# ===== STEP 5: Setup build environment =====
echo "Setting up build environment..."
. build/envsetup.sh
lunch omni_${DEVICE_CODENAME}-eng

# ===== STEP 6: Build recovery =====
echo "Building TWRP recovery..."
mkdir -p $LOGDIR
mka recoveryimage 2>&1 | tee $LOGDIR/build.log

# ===== STEP 7: Output =====
echo "Build finished!"
echo "Recovery image: $WORKDIR/out/target/product/$DEVICE_CODENAME/recovery.img"
echo "Build log: $LOGDIR/build.log"
