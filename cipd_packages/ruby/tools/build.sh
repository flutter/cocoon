#!/bin/bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fetches corresponding dart sdk from CIPD for different platforms, builds
# an executable binary of codesign to `build` folder.
#
# This build script will be triggered on Mac code signing machines.

set -e
set -x

# Get the directory of this script.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get versions from config files.
RUBY_MAJOR_VERSION=$(cat $DIR/../ruby_metadata.txt | cut -d ',' -f 1)
RUBY_FILE_NAME=$(cat $DIR/../ruby_metadata.txt | cut -d ',' -f 2)


# Create the package structure.
rm -rf $DIR/../build && mkdir -p $DIR/../build
mkdir -p $DIR/../build/tools

# Copy files to build directory.
cp $DIR/auto_relink_dylibs.rb $DIR/../build/tools/auto_relink_dylibs.rb
cp $DIR/../LICENSE $DIR/../build/LICENSE

# Download ruby.
mkdir -p $DIR/../cleanup 
curl https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_VERSION/$RUBY_FILE_NAME -o $DIR/../cleanup/$RUBY_FILE_NAME

# Install brew dependencies
brew install --build-from-source gdbm
brew install --build-from-source gmp
brew install --build-from-source libffi
brew install libyaml
brew install --build-from-source readline
brew install --build-from-source openssl@3
brew install --build-from-source m4

# Change directory to ruby_ship checkout
$DIR/ruby_build.sh $DIR/../cleanup/$RUBY_FILE_NAME

$DIR/../build/bin/ruby $DIR/../build/tools/auto_relink_dylibs.rb

# Remove signatures
ls $DIR/../build/bin/darwin_ruby/dylibs/* | xargs codesign --remove-signature

# Resign with adhoc
ls $DIR/../build/bin/darwin_ruby/dylibs/* | xargs codesign --force -s -
codesign --remove-signature $DIR/../build/bin/darwin_ruby/bin/ruby
codesign --force -s - $DIR/../build/bin/darwin_ruby/bin/ruby

# Update wrapper scripts to make them use libraries from new location.
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' $DIR/../build/bin/darwin_ruby/bin/gem
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' $DIR/../build/bin/darwin_ruby/bin/bundler
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' $DIR/../build/bin/darwin_ruby/bin/bundle
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' $DIR/../build/bin/darwin_ruby/bin/pod

# Ensure all the command are working properly
$DIR/../build/bin/bundle --version
$DIR/../build/bin/bundler --version
$DIR/../build/bin/gem --version
$DIR/../build/bin/pod --version
