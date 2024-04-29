#!/bin/bash -e
# This script is one huge hack to build Flutter's engine for ARM inside Buildroot.
# Buildroot's extension points don't play nice with Google's massive toolchain.
# We have to hack around a lot of weird assumptions Google makes about the host system...
#
# Assuming our host systems will only ever be x86_64 or aarch64 for now...
# Dart cannot be built on mismatched bit archs UNLESS you're running x86_64
# This is known as simarm_x64, it's the only case where you can compile on a different host bit type
#
# TLDR:
#     Host     Target   Allowed
#     ----     ------   -------
#     x86_64   armv7    YES
#     x86_64   aarch64  YES
#     aarch64  armv7    NOPE
#     aarch64  aarch64  YES
#     aarch64  x86_64   YES
#
# - Digit

LLVM_AARCH64_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/clang+llvm-13.0.1-aarch64-linux-gnu.tar.xz"

stderr_log(){ >&2 echo "[LIBFLUTTER] $@"; }

HOST_ARCH=$(uname -m)

WORK_DIR=$1
HOST_DIR=$2
BUILD_TYPE=$3
TARGET_PREFIX=$4

FLUTTER_ENGINE_VERSION=$(cat $WORK_DIR/engine.version)

BASE_DIR=$(pwd)
cd $WORK_DIR

stderr_log "Working in: $WORK_DIR"

# Download Depot Tools
if [ ! -d "depot_tools" ] ; then
    stderr_log "Fetching depot_tools..."
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

# Ensure google's tools are in the PATH
export TAR_OPTIONS="--no-same-owner"
export PATH=$PATH:$(pwd)/depot_tools

# We need Clang 13.x for x86_64 or aarch64
stderr_log "Fetching LLVM and Clang for your host platform..."
if [[ "$HOST_ARCH" == *"x86_64"* ]]; then
  echo "No toolchain to fetch!"
elif [[ "$HOST_ARCH" == *"aarch64"* ]]; then
  wget -nc $LLVM_AARCH64_URL

  if [ ! -d "toolchain" ] ; then
    stderr_log "Extracting..."
    mkdir -p toolchain
    tar xf clang+llvm*.tar.xz -C $WORK_DIR/toolchain/ --strip-components 1 --no-same-owner
  fi

  # Ninja/gn expects the ar, readelf, nm, ld and strip binaries for the target platform to live in the same directory as the LLVM toolchain
  ln -sf $HOST_DIR/bin/$TARGET_PREFIX-ar $WORK_DIR/toolchain/bin/$TARGET_PREFIX-ar
  ln -sf $HOST_DIR/bin/$TARGET_PREFIX-readelf $WORK_DIR/toolchain/bin/$TARGET_PREFIX-readelf
  ln -sf $HOST_DIR/bin/$TARGET_PREFIX-strip $WORK_DIR/toolchain/bin/$TARGET_PREFIX-strip
  ln -sf $HOST_DIR/bin/$TARGET_PREFIX-nm $WORK_DIR/toolchain/bin/$TARGET_PREFIX-nm
  ln -sf $HOST_DIR/bin/$TARGET_PREFIX-ld $WORK_DIR/toolchain/bin/$TARGET_PREFIX-ld
else
  stderr_log "Unsupported host type! Cannot build flutter!"
  exit 1
fi

stderr_log "Engine version: $FLUTTER_ENGINE_VERSION"

# Create the gclient config file to tell gclient which version of the Flutter engine to clone
cat > .gclient <<- EndOfMessage
solutions = [
  {
    "managed": False,
    "name": "src/flutter",
    "url": "https://github.com/flutter/engine.git@$FLUTTER_ENGINE_VERSION",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
EndOfMessage

# Sync the engine source code
stderr_log "Syncing with gclient, this may take a LONG time..."
gclient sync --with_branch_heads --no-history

# The big build command, tell flutter where our sysroot is, and to use our toolchain dir
# we also disable examples, and things that require GTK+ and X11 etc.

if [[ "$TARGET_PREFIX" == *"aarch64"* ]]; then
  LINUX_OPTIONS_CPU="arm64"

  stderr_log "Configure Flutter Engine for ARM 64 Bit..."
  src/flutter/tools/gn \
      --no-goma \
      --target-os linux \
      --linux-cpu $LINUX_OPTIONS_CPU \
      --target-triple $TARGET_PREFIX \
      --runtime-mode $BUILD_TYPE \
      --lto \
      --target-sysroot=$WORK_DIR/src/build/linux/debian_sid_$LINUX_OPTIONS_CPU-sysroot \
      --embedder-for-target \
      --disable-desktop-embeddings \
      --no-prebuilt-dart-sdk \
      --no-build-embedder-examples \
      --verbose \
      --out $WORK_DIR/build
else
  LINUX_OPTIONS_CPU="arm"

  stderr_log "Configure Flutter Engine for ARM 32 Bit..."
  src/flutter/tools/gn \
      --no-goma \
      --target-os linux \
      --linux-cpu $LINUX_OPTIONS_CPU \
      --arm-float-abi hard \
      --target-triple $TARGET_PREFIX \
      --runtime-mode $BUILD_TYPE \
      --lto \
      --target-toolchain=$(pwd)/toolchain \
      --target-sysroot=$WORK_DIR/src/build/linux/debian_sid_$LINUX_OPTIONS_CPU-sysroot \
      --embedder-for-target \
      --disable-desktop-embeddings \
      --no-prebuilt-dart-sdk \
      --no-build-embedder-examples \
      --verbose \
      --out $WORK_DIR/build

  # Download Google's ARM sysroot which will provide all the libcxx libs needed for linking the final library
  $WORK_DIR/depot_tools/python-bin/python3 $WORK_DIR/src/build/linux/sysroot_scripts/install-sysroot.py --arch arm
fi

stderr_log "Compiling Flutter Engine..."

# Build it!
$HOST_DIR/bin/ninja -C $WORK_DIR/build/out/linux_$BUILD_TYPE\_$LINUX_OPTIONS_CPU
