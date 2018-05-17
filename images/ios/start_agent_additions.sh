# Add homebrew to path.
export PATH="/Volumes/DevicelabIOS/homebrew/bin:$PATH"

# Add Cocoapods to path, link user-local .gem directory.
if [[ ! -e "$HOME/.gem" ]]; then
  ln -s "/Volumes/DevicelabIOS/gem" "$HOME/.gem"
fi
export PATH="$HOME/.gem/ruby/2.3.0/bin:$PATH"
