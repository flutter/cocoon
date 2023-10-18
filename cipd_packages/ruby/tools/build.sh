#!/usr/bin/env bash
# Copyright 2019 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script to build a self contained ruby cipd packages.

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
cp $DIR/../third_party/ruby_ship/auto_relink_dylibs.rb $DIR/../build/tools/auto_relink_dylibs.rb
cp $DIR/../third_party/ruby_ship/ruby_ship_build.sh $DIR/ruby_build.sh
cp $DIR/../LICENSE $DIR/../build/LICENSE

# Download ruby.
mkdir -p $DIR/../cleanup
curl https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_VERSION/$RUBY_FILE_NAME -o $DIR/../cleanup/$RUBY_FILE_NAME

# Install brew dependencies
brew install gdbm@1
brew install gmp@6
brew install libffi@3
brew install libyaml@0
brew install readline@8
brew install openssl@3
brew install m4@1

bash -e $DIR/ruby_build.sh $DIR/../cleanup/$RUBY_FILE_NAME

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
