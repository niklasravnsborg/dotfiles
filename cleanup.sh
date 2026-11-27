#!/bin/bash

# Homebrew
brew cleanup --prune=all

# Nix
nix-collect-garbage --delete-older-than 30d

# Docker
open -a Docker
docker system prune -a # Continue when Docker daemon is running
