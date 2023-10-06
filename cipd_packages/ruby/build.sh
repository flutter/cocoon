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

# Get versions from config files.
RUBY_MAJOR_VERSION=$(cat ruby_version.txt | cut -d ',' -f 1)
RUBY_FILE_NAME=$(cat ruby_version.txt | cut -d ',' -f 2)
COCOAPODS_VERSION=$(cat cocoapods_version.txt)

# Cleanup ruby_ship/bin directory if it exists.
rm -rf ruby_ship/bin
pushd ruby_ship
# Download a ruby version
curl https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR_VERSION/$RUBY_FILE_NAME -o ../$RUBY_FILE_NAME
# Install brew dependencies
brew install --build-from-source gdbm
brew install --build-from-source gmp
brew install --build-from-source libffi
brew install libyaml
brew install --build-from-source readline
brew install --build-from-source openssl@3
brew install --build-from-source m4
# Change directory to ruby_ship checkout
./tools/ruby_ship_build.sh ../$RUBY_FILE_NAME
bin/ruby tools/auto_relink_dylibs.rb
# Remove signatures
ls bin/shipyard/darwin_ruby/dylibs/* | xargs codesign --remove-signature
# Resign with adhoc
ls bin/shipyard/darwin_ruby/dylibs/* | xargs codesign --force -s -
codesign --remove-signature bin/shipyard/darwin_ruby/bin/ruby
codesign --force -s - bin/shipyard/darwin_ruby/bin/ruby
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' bin/shipyard/darwin_ruby/bin/gem
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' bin/shipyard/darwin_ruby/bin/bundler
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' bin/shipyard/darwin_ruby/bin/bundle
bin/shipyard/darwin_ruby/bin/bundle --version
bin/shipyard/darwin_ruby/bin/bundler --version
bin/shipyard/darwin_ruby/bin/gem --version

# Post install cocoapod
bin/shipyard/darwin_gem.sh install cocoapods -v $COCOAPODS_VERSION
sed -i'' -e 's/bindir="\${0%\/\*}"/&\nLIBSPATH="\$( cd -- "\$(dirname "\$0")" >\/dev\/null 2>\&1 ; pwd -P )\/..\/dylibs"\nexport DYLD_FALLBACK_LIBRARY_PATH=\$LIBSPATH:\$DYLD_FALLBACK_LIBRARY_PATH/' bin/shipyard/darwin_ruby/bin/pod
bin/shipyard/darwin_ruby/bin/pod --version
popd
