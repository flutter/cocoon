#!/usr/bin/env bash
#VERIFY PARAMETERS
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: nix_compile_ruby.sh /path/to/ruby_source.tar.gz"
    exit 1
fi

#DETECT OPERATING SYSTEM
OS="unknown"
if [[ "$OSTYPE" == "linux"* ]]; then
	OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	OS="darwin"
elif [[ "$OSTYPE" == "cygwin" ]]; then
	OS="cygwin"
elif [[ "$OSTYPE" == "win32" ]]; then
	OS="win32"
elif [[ "$OSTYPE" == "FreeBSD"* ]]; then
	OS="freebsd"
fi

#DETERMINE DIRECTORY OF THIS SCRIPT
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Compiling and installing ruby"

#PRE INSTALL CLEANUP
rm -rf $DIR/extracted_ruby
mkdir $DIR/extracted_ruby

#UNZIP SOURCE
tar -xzf $1 -C $DIR/extracted_ruby

#GET RUBY VERSION AND DIRECTORY
RUBYDIR="$(ls $DIR/extracted_ruby)"
RUBY_VERSION="$(echo $RUBYDIR | cut -d'-' -f 2)"

echo "############################"
echo "Ruby Ship is installing ruby version $RUBY_VERSION"
echo "############################"

#BUILDING RUBY
cd $DIR/extracted_ruby/$RUBYDIR
if [[ "$OS" == "darwin" ]]; then
	$DIR/extracted_ruby/$RUBYDIR/configure --enable-load-relative --prefix=$DIR/../bin/shipyard/${OS}_ruby --with-opt-dir="$(brew --prefix openssl):$(brew --prefix readline):$(brew --prefix libyaml):$(brew --prefix gdbm):$(brew --prefix libffi)" 
else
	$DIR/extracted_ruby/$RUBYDIR/configure --enable-load-relative --prefix=$DIR/../bin/shipyard/${OS}_ruby
fi
make
make install


#SETTING UP REFERENCE DIRECTORIES
RUBY_INSTALL_DIR="$(ls $DIR/../bin/shipyard/${OS}_ruby/include)"
RUBY_VERSION_DIR="$(echo $RUBY_INSTALL_DIR | cut -d'-' -f 2)"
RUBY_BINARY_INSTALL_DIR="$(ls $DIR/../bin/shipyard/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR | grep ${OS})"

#SETTING UP COMMON WRAPPER COMPONENTS
OS_SELECTOR=$'#!/usr/bin/env bash\nOS=\"unknown\"\nif [[ \"$OSTYPE\" == \"linux\"* ]]; then\n	OS=\"linux\"\nelif [[ \"$OSTYPE\" == \"darwin\"* ]]; then\n	OS=\"darwin\"\nelif [[ \"$OSTYPE\" == \"cygwin\" ]]; then\n	OS=\"win\"\nelif [[ \"$OSTYPE\" == \"win32\" ]]; then\n	OS=\"win\"\nelif [[ \"$OSTYPE\" == \"FreeBSD\"* ]]; then\n	OS=\"freebsd\"\nelse\n	echo \"OS not compatible\"\n	exit 1\nfi\n'
DIR_SETTER="DIR=\"\$( cd \"\$( dirname \"\${BASH_SOURCE[0]}\" )\" && pwd )\""




#BUILDING RUBY SHIP WRAPPERS:
#ruby_ship
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_ruby.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship.sh

#ruby_ship_gem
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_gem.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_gem.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_gem.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_gem.sh

#ruby_ship_erb
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_erb.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_erb.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_erb.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_erb.sh

#ruby_ship_irb
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_irb.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_irb.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_irb.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_irb.sh

#ruby_ship_rake
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_rake.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_rake.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_rake.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_rake.sh

#ruby_ship_rdoc
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_rdoc.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_rdoc.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_rdoc.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_rdoc.sh

#ruby_ship_ri
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_ri.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_ri.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_ri.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_ri.sh

#ruby_ship_testrb
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_testrb.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_testrb.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_testrb.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_testrb.sh

#ruby_ship_bundle
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_bundle.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_bundle.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_bundle.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_bundle.sh

#ruby_ship_bundler
echo "$OS_SELECTOR" > $DIR/../bin/ruby_ship_bundler.sh
echo "$DIR_SETTER" >> $DIR/../bin/ruby_ship_bundler.sh
echo "SSL_CERT_FILE=\"\${DIR}/shipyard/cacerts.pem\" \"\${DIR}/shipyard/\${OS}_bundler.sh\" \"\$@\"" >> $DIR/../bin/ruby_ship_bundler.sh




#MAKING THE OS SPECIFIC SCRIPTS:

GEM_PATH_SETTER="GEM_PATH=\"\${DIR}/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/:\${DIR}/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR/:\${DIR}/${OS}_ruby/bin/:\${DIR}/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR/$RUBY_BINARY_INSTALL_DIR/\""
GEM_HOME_SETTER="GEM_HOME=\"\${DIR}/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/\""

#OS_ruby
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_ruby.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_ruby.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_ruby.sh
echo "\"\${DIR}/${OS}_ruby/bin/ruby\" -I \"\${DIR}/shipyard/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/\" -I \"\${DIR}/shipyard/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR/\" -I \"\${DIR}/shipyard/${OS}_ruby/bin/\" -I \"\${DIR}/shipyard/${OS}_ruby/lib/ruby/$RUBY_VERSION_DIR/$RUBY_BINARY_INSTALL_DIR/\"" \"\$@\" >> $DIR/../bin/shipyard/${OS}_ruby.sh

#gem command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_gem.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_gem.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_gem.sh
echo "\"\${DIR}/${OS}_ruby/bin/gem\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_gem.sh
if [[ "$OS" == "darwin" ]]; then
	echo "if [[ \"\$1\" == \"install\" ]]; then" >> $DIR/../bin/shipyard/${OS}_gem.sh
	echo "  cd \"\${DIR}/../../\"" >> $DIR/../bin/shipyard/${OS}_gem.sh
	echo "  ruby \"./tools/auto_relink_dylibs.rb\"" >> $DIR/../bin/shipyard/${OS}_gem.sh
	echo "fi" >> $DIR/../bin/shipyard/${OS}_gem.sh
	# echo "echo \"Remember to run 'ruby tools/auto_relink_dylibs.rb' after you install new gems\"" >> $DIR/../bin/shipyard/${OS}_gem.sh
fi
#erb command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_erb.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_erb.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_erb.sh
echo "\"\${DIR}/${OS}_ruby/bin/erb\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_erb.sh

#irb command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_irb.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_irb.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_irb.sh
echo "\"\${DIR}/${OS}_ruby/bin/irb\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_irb.sh

#rake command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_rake.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_rake.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_rake.sh
echo "\"\${DIR}/${OS}_ruby/bin/rake\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_rake.sh

#rdoc command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_rdoc.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_rdoc.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_rdoc.sh
echo "\"\${DIR}/${OS}_ruby/bin/rdoc\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_rdoc.sh

#ri command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_ri.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_ri.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_ri.sh
echo "\"\${DIR}/${OS}_ruby/bin/ri\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_ri.sh

#testrb command script:
echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_testrb.sh
echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_testrb.sh
echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_testrb.sh
echo "\"\${DIR}/${OS}_ruby/bin/testrb\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_testrb.sh


#for some reason darwin installs bundler to a strange location.
if [[ "$OS" == "darwin" ]]; then
	#bundle command script darwin:
	echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "\"\${DIR}/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/bin/bundle\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "if [ \"\$1\" == \"install\" ] || [ \"\$1\" == \"update\" ]; then" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "  cd \"\${DIR}/../../\"" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "  ruby \"./tools/auto_relink_dylibs.rb\"" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "fi" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	#bundler command script darwin:
	echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "\"\${DIR}/${OS}_ruby/lib/ruby/gems/$RUBY_VERSION_DIR/bin/bundler\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_bundler.sh
else
	#bundle command script:
	echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	echo "\"\${DIR}/${OS}_ruby/bin/bundle\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_bundle.sh
	#bundler command script:
	echo "$DIR_SETTER" > $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "$GEM_PATH_SETTER" >> $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "$GEM_HOME_SETTER" >> $DIR/../bin/shipyard/${OS}_bundler.sh
	echo "\"\${DIR}/${OS}_ruby/bin/bundler\" \"\$@\"" >> $DIR/../bin/shipyard/${OS}_bundler.sh
fi

chmod a+x $DIR/../bin/ruby_ship.sh
chmod a+x $DIR/../bin/ruby_ship_gem.sh
chmod a+x $DIR/../bin/ruby_ship_erb.sh
chmod a+x $DIR/../bin/ruby_ship_irb.sh
chmod a+x $DIR/../bin/ruby_ship_rake.sh
chmod a+x $DIR/../bin/ruby_ship_rdoc.sh
chmod a+x $DIR/../bin/ruby_ship_ri.sh
chmod a+x $DIR/../bin/ruby_ship_testrb.sh
chmod a+x $DIR/../bin/ruby_ship_bundle.sh
chmod a+x $DIR/../bin/ruby_ship_bundler.sh

chmod a+x $DIR/../bin/shipyard/${OS}_ruby.sh
chmod a+x $DIR/../bin/shipyard/${OS}_gem.sh
chmod a+x $DIR/../bin/shipyard/${OS}_erb.sh
chmod a+x $DIR/../bin/shipyard/${OS}_irb.sh
chmod a+x $DIR/../bin/shipyard/${OS}_rake.sh
chmod a+x $DIR/../bin/shipyard/${OS}_rdoc.sh
chmod a+x $DIR/../bin/shipyard/${OS}_ri.sh
chmod a+x $DIR/../bin/shipyard/${OS}_testrb.sh
chmod a+x $DIR/../bin/shipyard/${OS}_bundle.sh
chmod a+x $DIR/../bin/shipyard/${OS}_bundler.sh

#CLEAN UP AFTER EXTRACTION
rm -rf $DIR/extracted_ruby


#NOTIFY USER ON HOW TO USE RUBY SHIP
echo "############################"
echo "############DONE############"
echo "############################"
echo "Ruby Ship finished installing Ruby $RUBY_VERSION!"
echo "Run scripts by using the bin/ruby_ship.sh as you would use the normal ruby command."
echo "Eg.: bin/ruby_ship.sh -v"
echo "=> ruby $RUBY_VERSION..."
