#!/bin/bash

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies with brew
brew bundle --file=macos/Brewfile

echo "Configure macOS"
./macos/defaults.sh

echo "Install custom keyboard"
./macos/keyboard.sh

echo "Fix GPG pinentry"
./macos/pinentry.sh

echo "Install tmux plugin manager"
./tmux/setup.sh

dotbot -c install.conf.yaml
