#!/bin/bash

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## Run these three commands in your terminal to add Homebrew to your PATH:
echo '# Set PATH, MANPATH, etc., for Homebrew.' >> /Users/mgr/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/mgr/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install dependencies with brew
brew bundle --file=macos/Brewfile

echo "Configure macOS"
./macos/defaults.sh

# echo "Install custom keyboard"
# ./macos/keyboard.sh

# echo "Fix GPG pinentry"
# ./macos/pinentry.sh

# echo "Install tmux plugin manager"
# ./tmux/setup.sh

dotbot -c install.conf.yaml
