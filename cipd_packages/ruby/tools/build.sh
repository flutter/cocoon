#!/bin/bash

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
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  sudo chown -R $(whoami) /usr/local/Homebrew
else
  sudo chown -R $(whoami) /usr/local/Cellar
fi
brew install --build-from-source gdbm
brew install --build-from-source gmp
brew install --build-from-source libffi
brew install libyaml
brew install --build-from-source readline
brew install --build-from-source openssl@3
brew install --build-from-source m4

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
