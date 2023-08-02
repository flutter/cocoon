#!/usr/bin/env bash
# Copyright 2020 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fetches Doxygen from GitHub, and builds it from source.
#
# This currently supports linux and mac.

set -e

command -v cipd > /dev/null || {
  echo "Please install CIPD (available from depot_tools) and add to path first.";
  exit -1;
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
BUILD_DIR="$( dirname "$DIR" )/build"
SRC_DIR="$( dirname "$DIR" )/doxygen_src"
OS="`uname`"
RELEASE="Release_1_9_7"
if [[ $OS == "Darwin" ]]; then
  NUM_CPUS=$(sysctl -n hw.ncpu)
else
  NUM_CPUS=$(grep -c processor /proc/cpuinfo)
fi

function fetch_doxygen() (
  cd "$SRC_DIR"
  wget -O doxygen.tar.gz "https://github.com/doxygen/doxygen/archive/refs/tags/${RELEASE}.tar.gz"
  tar xf doxygen.tar.gz
  rm -f doxygen.tar.gz
  mv "doxygen-$RELEASE"/* "doxygen-$RELEASE"/.??* .
  rm -rf "doxygen-$RELEASE"
)

function build_doxygen() (
  local bison_opt=
  if [[ $OS == "Darwin" ]]; then
    # On macOS, doxygen needs an updated version of bison to build with.
    bison_opt="-DBISON_EXECUTABLE=/opt/homebrew/opt/bison/bin/bison"
  fi

  cd "$SRC_DIR"
  cmake "-DCMAKE_INSTALL_PREFIX=$BUILD_DIR" $bison_opt
  make -j$NUM_CPUS install
)

function setup() (
  cd "$DIR/.."
  pwd
  ls tool
  if [[ -d "$BUILD_DIR" ]]; then
    echo "Please remove the build directory '$BUILD_DIR' before proceeding"
    exit -1
  fi
  mkdir -p "$BUILD_DIR"
  if [[ -d "$SRC_DIR" ]]; then
    echo "Please remove the downloaded source directory '$SRC_DIR' before proceeding"
    exit -1
  fi
  mkdir -p "$SRC_DIR"
)

setup
fetch_doxygen
build_doxygen