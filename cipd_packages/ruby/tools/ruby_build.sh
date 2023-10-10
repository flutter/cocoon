#!/usr/bin/env bash
# Copyright 2023 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e
set -x


# Verify parameters.
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: ruby_build.sh /path/to/ruby_source.tar.gz"
    exit 1
fi

# This script supports only Mac.
OS="darwin"

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

COCOAPODS_VERSION=$(cat $DIR/../cocoapods_version.txt)

echo "Compiling and installing ruby"

# Pre install/cleanup
rm -rf $DIR/../cleanup/extracted_ruby
mkdir $DIR/../cleanup/extracted_ruby

# Unzip source code.
tar -xzf $1 -C $DIR/../cleanup/extracted_ruby

#Get ruby version and directory.
RUBYDIR="$(ls $DIR/../cleanup/extracted_ruby)"
RUBY_VERSION="$(echo $RUBYDIR | cut -d'-' -f 2)"

echo "############################"
echo "Ruby Ship is installing ruby version $RUBY_VERSION"
echo "############################"

# Building ruby.
cd $DIR/../cleanup/extracted_ruby/$RUBYDIR
if [[ "$OS" == "darwin" ]]; then
  OPTS=""
  OPTS+="$(brew --prefix openssl)"
  OPTS+=":$(brew --prefix readline)"
  OPTS+=":$(brew --prefix libyaml)"
  OPTS+=":$(brew --prefix gdbm)"
  OPTS+=":$(brew --prefix libffi)"
  OPTS+=":$(brew --prefix gdbm)"
  OPTS+=":$(brew --prefix libffi)"
  $DIR/../cleanup/extracted_ruby/$RUBYDIR/configure \
  --enable-load-relative \
  --prefix=$DIR/../build/bin/${OS}_ruby \
  --with-opt-dir="$OPTS"
fi
make
make install

# Setting up reference directories.
RUBY_INSTALL_DIR="$(ls $DIR/../build/bin/${OS}_ruby/include)"
RUBY_VERSION_DIR="$(echo $RUBY_INSTALL_DIR | cut -d'-' -f 2)"
RUBY_BINARY_INSTALL_DIR="$(ls $DIR/../build/bin/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR | grep ${OS})"

#SETTING UP COMMON WRAPPER COMPONENTS
OS_SELECTOR=$'#!/usr/bin/env bash\nOS=\"darwin\"\n'
DIR_SETTER="DIR=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\""




#Building wrappers.

#ruby
echo "$OS_SELECTOR" > $DIR/../build/bin/ruby
echo "$DIR_SETTER" >> $DIR/../build/bin/ruby
echo "\"\${DIR}/\${OS}_ruby/\${OS}_ruby.sh\" \"\$@\"" >> $DIR/../build/bin/ruby

#gem
echo "$OS_SELECTOR" > $DIR/../build/bin/gem
echo "$DIR_SETTER" >> $DIR/../build/bin/gem
echo "\"\${DIR}/\${OS}_ruby/\${OS}_gem.sh\" \"\$@\"" >> $DIR/../build/bin/gem

#erb
echo "$OS_SELECTOR" > $DIR/../build/bin/erb
echo "$DIR_SETTER" >> $DIR/../build/bin/erb
echo "\"\${DIR}/\${OS}_ruby/\${OS}_erb.sh\" \"\$@\"" >> $DIR/../build/bin/erb

#irb
echo "$OS_SELECTOR" > $DIR/../build/bin/irb
echo "$DIR_SETTER" >> $DIR/../build/bin/irb
echo "\"\${DIR}/\${OS}_ruby/\${OS}_irb.sh\" \"\$@\"" >> $DIR/../build/bin/irb

#rake
echo "$OS_SELECTOR" > $DIR/../build/bin/rake
echo "$DIR_SETTER" >> $DIR/../build/bin/rake
echo "\"\${DIR}/\${OS}_ruby/\${OS}_rake.sh\" \"\$@\"" >> $DIR/../build/bin/rake

#rdoc
echo "$OS_SELECTOR" > $DIR/../build/bin/rdoc
echo "$DIR_SETTER" >> $DIR/../build/bin/rdoc
echo "\"\${DIR}/\${OS}_ruby/\${OS}_rdoc.sh\" \"\$@\"" >> $DIR/../build/bin/rdoc

#ri
echo "$OS_SELECTOR" > $DIR/../build/bin/ri
echo "$DIR_SETTER" >> $DIR/../build/bin/ri
echo "\"\${DIR}/\${OS}_ruby/\${OS}_ri.sh\" \"\$@\"" >> $DIR/../build/bin/ri

#bundle
echo "$OS_SELECTOR" > $DIR/../build/bin/bundle
echo "$DIR_SETTER" >> $DIR/../build/bin/bundle
echo "\"\${DIR}/\${OS}_ruby/\${OS}_ri.sh\" \"\$@\"" >> $DIR/../build/bin/bundle

#bundler
echo "$OS_SELECTOR" > $DIR/../build/bin/bundler
echo "$DIR_SETTER" >> $DIR/../build/bin/bundler
echo "\"\${DIR}/\${OS}_ruby/\${OS}_bundler.sh\" \"\$@\"" >> $DIR/../build/bin/bundler

#pod
echo "$OS_SELECTOR" > $DIR/../build/bin/pod
echo "$DIR_SETTER" >> $DIR/../build/bin/pod
echo "\"\${DIR}/\${OS}_ruby/\${OS}_pod.sh\" \"\$@\"" >> $DIR/../build/bin/pod


# Making OS specific scripts:

GEM_PATH_SETTER="GEM_PATH=\"\${DIR}/lib/ruby/gems/$RUBY_VERSION_DIR/:\${DIR}/lib/ruby/$RUBY_VERSION_DIR/:\${DIR}/bin/:\${DIR}/lib/ruby/$RUBY_VERSION_DIR/$RUBY_BINARY_INSTALL_DIR/\""
GEM_HOME_SETTER="GEM_HOME=\"\${DIR}/lib/ruby/gems/$RUBY_VERSION_DIR/\""

# OS_ruby
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_ruby.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_ruby.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_ruby.sh
echo "\"\${DIR}/bin/ruby\" -I \"\${DIR}/lib/ruby/gems/$RUBY_VERSION_DIR/\" -I \"\${DIR}/lib/ruby/$RUBY_VERSION_DIR/\" -I \"\${DIR}/bin/\" -I \"\${DIR}/lib/ruby/$RUBY_VERSION_DIR/$RUBY_BINARY_INSTALL_DIR/\"" \"\$@\" >> $DIR/../build/bin/${OS}_ruby/${OS}_ruby.sh

# gem command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "\"\${DIR}/bin/gem\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "if [[ \"\$1\" == \"install\" ]]; then" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "  ${DIR}/../build/bin/ruby \"\${DIR}/../../../tools/auto_relink_dylibs.rb\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
echo "fi" >> $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh

# erb command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_erb.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_erb.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_erb.sh
echo "\"\${DIR}/bin/erb\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_erb.sh

# irb command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_irb.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_irb.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_irb.sh
echo "\"\${DIR}/bin/irb\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_irb.sh

# rake command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_rake.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_rake.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_rake.sh
echo "\"\${DIR}/bin/rake\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_rake.sh

# rdoc command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_rdoc.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_rdoc.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_rdoc.sh
echo "\"\${DIR}/bin/rdoc\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_rdoc.sh

#ri command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_ri.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_ri.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_ri.sh
echo "\"\${DIR}/bin/ri\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_ri.sh

# pod command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_pod.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_pod.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_pod.sh
echo "\"\${DIR}/bin/pod\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_pod.sh


# bundle command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "\"\${DIR}/../build/bin/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/bin/bundle\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "if [ \"\$1\" == \"install\" ] || [ \"\$1\" == \"update\" ]; then" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "  ${DIR}/../build/bin/ruby \"\${DIR}/../../auto_relink_dylibs.rb\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
echo "fi" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh

#bundler command script:
echo "$DIR_SETTER" > $DIR/../build/bin/${OS}_ruby/${OS}_bundler.sh
echo "$GEM_PATH_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundler.sh
echo "$GEM_HOME_SETTER" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundler.sh
echo "\"\${DIR}/bin/bundler\" \"\$@\"" >> $DIR/../build/bin/${OS}_ruby/${OS}_bundler.sh

chmod a+x $DIR/../build/bin/ruby
chmod a+x $DIR/../build/bin/gem
chmod a+x $DIR/../build/bin/erb
chmod a+x $DIR/../build/bin/irb
chmod a+x $DIR/../build/bin/pod
chmod a+x $DIR/../build/bin/rake
chmod a+x $DIR/../build/bin/rdoc
chmod a+x $DIR/../build/bin/ri
chmod a+x $DIR/../build/bin/bundle
chmod a+x $DIR/../build/bin/bundler

chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_ruby.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_gem.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_erb.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_irb.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_rake.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_rdoc.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_ri.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_bundle.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_bundler.sh
chmod a+x $DIR/../build/bin/${OS}_ruby/${OS}_pod.sh


# Install bundler
$DIR/../build/bin/gem cleanup -f bundler
$DIR/../build/bin/gem install -f bundler

# Install cococoapods
$DIR/../build/bin/gem install activesupport -v 7.0.8 # Pin this dep version.
$DIR/../build/bin/gem install cocoapods -v $COCOAPODS_VERSION


# Cleanup temp folder. 
rm -rf $DIR/../cleanup


#NOTIFY USER ON HOW TO USE RUBY SHIP
echo "############################"
echo "############DONE############"
echo "############################"
echo "Finished creating bundler for Ruby $RUBY_VERSION!"
echo "Run scripts by using scripts in the bin/ as you would use the normal ruby command."
echo "Eg.: bin/ruby -v"
echo "=> ruby $RUBY_VERSION..."
