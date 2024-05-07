{ pkgs, ... }: {

  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;

  # Create sourcings for zsh and fish
  programs.zsh.enable = true;
  programs.fish.enable = true;

  users.users.nik.home = "/Users/nik";

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "azure/azd"
      "azure/functions"
      "dapr/tap"
      "finestructure/hummingbird"
      "heroku/brew"
      "homebrew/cask-fonts"
      "nektos/tap"
      "oven-sh/bun"
    ];

    brews = [
      "azure-cli" # Microsoft Azure CLI 2.0
      "composer" # Dependency Manager for PHP
      "firebase-cli" # Firebase command-line tools
      "fisher" # Plugin manager for the Fish shell
      "go" # Open source programming language to build simple/reliable/efficient software
      "node@18" # Platform built on V8 to build network applications
      "php-cs-fixer" # Tool to automatically fix PHP coding standards issues
      "php" # General-purpose scripting language
      "phpunit" # Programmer-oriented testing framework for PHP
      "postgresql@14" # Object-relational database system
      "python@3.10" # Interpreted, interactive, object-oriented programming language
      "ruby" # Powerful, clean, object-oriented scripting language

      "azure/azd/azd" # Azure Developer CLI
      "azure/functions/azure-functions-core-tools@4" # Azure Functions Core Tools 4.0
      "dapr/tap/dapr-cli" # Client for Dapr.
      "oven-sh/bun/bun" # Incredibly fast JavaScript runtime, bundler, transpiler and package manager - all in one.
      "pulumi/tap/pulumictl" # A swiss army knife for Pulumi development
    ];

    casks = [
      # Fonts
      "font-dm-sans"
      "font-inter"
      "font-kumbh-sans"
      "font-lexend"
      "font-montserrat"
      "font-open-sans"
      "font-poppins"
      "font-palanquin"
      "font-roboto"
      "font-space-grotesk"
      "font-source-sans-3"

      # Nerd Fonts
      "font-jetbrains-mono-nerd-font"
      "font-sauce-code-pro-nerd-font"
      "font-hack-nerd-font"
      "font-anonymous-pro"

      # Applications
      "affinity-designer" # Professional graphic design software
      "affinity-photo" # Professional image editing software
      "alacritty" # GPU-accelerated terminal emulator
      "arc" # Chromium based browser
      "bitwarden" # Desktop password and login vault
      "blackhole-2ch" # Virtual Audio Driver
      "calibre" # E-books management software
      "codewhisperer" # AI-powered productivity tool for the command-line
      "cyberduck" # Server and cloud storage browser
      "dbngin" # Database version management tool
      "discord" # Voice and text chat software
      "docker" # App to build and share containerised applications and microservices
      "dropbox" # Client for the Dropbox cloud storage service
      "figma" # Collaborative team software
      "finicky" # Utility for customizing which browser to start
      "firefox" # Web browser
      "flutter" # UI toolkit for building applications for mobile, web and desktop
      "fork" # GIT client
      "google-cloud-sdk" # Set of tools to manage resources and applications hosted on Google Cloud
      "gpg-suite" # Tools to protect your emails and files
      "httpie" # Testing client for REST, GraphQL, and HTTP APIs
      "imageoptim" # Tool to optimise images to a smaller size
      "iterm2" # Terminal emulator as alternative to Apple's Terminal app
      "logseq" # Privacy-first, open-source platform for knowledge sharing and management
      "macfuse" # File system integration
      "missive" # Team inbox and chat tool
      "mos" # Smooths scrolling and set mouse scroll directions independently
      "musescore" # Open-source music notation software
      "ngrok" # Reverse proxy, secure introspectable tunnels to localhost
      "nota" # Markdown files editor
      "notion" # App to write, plan, collaborate, and get organised
      "numi" # Calculator and converter application
      "obsidian" # Knowledge base that works on top of a local folder of plain text Markdown files
      "protonvpn" # VPN client focusing on security
      "proxyman" # HTTP debugging proxy
      "qlmarkdown" # Quick Look generator for Markdown files
      "raycast" # Control your tools with a few keystrokes
      "rectangle" # Move and resize windows using keyboard shortcuts or snap areas
      "rwts-pdfwriter" # Print driver for printing documents directly to a pdf file
      "signal" # Instant messaging application focusing on security
      "spotify" # Music streaming service
      "stats" # System monitor for the menu bar
      "tableplus" # Native GUI tool for relational databases
      "telegram" # Messaging app with a focus on speed and security
      "the-unarchiver" # Unpacks archive files
      "timemator" # Automatic time-tracking application
      "todoist" # To-do list
      "topnotch" # Utility to hide the notch
      "visual-studio-code" # Open-source code editor
      "vlc" # Multimedia player
      "warp" # Rust-based terminal
      "wireshark" # Network protocol analyzer
      "zoom" # Video communication and virtual meeting platform
    ];
  };
}
