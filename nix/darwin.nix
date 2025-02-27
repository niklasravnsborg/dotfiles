{
  pkgs,
  lib,
  config,
  secretsPath,
  ...
}:

with lib;

let
  home = "/Users/nik";
  appicon = name: {
    path = "/Applications/${name}.app";
    icon = "${home}/dotfiles/macos/icons/${name}.icns";
  };
in
{

  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;

  sops = {
    defaultSopsFile = "${secretsPath}/secrets.yaml";
    age.keyFile = "${home}/.config/sops/age/keys.txt";

    # Disable automatic key generation
    age.sshKeyPaths = [ ];
    gnupg.sshKeyPaths = [ ];

    secrets = {
      nextdns-config = { };
    };
  };

  services.nextdns.enable = true;
  launchd.daemons.nextdns = {
    # Uncomment to enable logging
    # serviceConfig.StandardErrorPath = "/var/log/nextdns.log";
    # serviceConfig.StandardOutPath = "/var/log/nextdns.log";
    command = mkForce (
      toString (
        pkgs.writeShellScript "nextdns-config-watch" ''
          trap 'kill $(jobs -p); exit' SIGINT

          # Make sure nextdns is activated
          ${pkgs.nextdns}/bin/nextdns activate

          while true; do
            # Start long-running nextdns process in the background
            ${pkgs.nextdns}/bin/nextdns run --config-file=${config.sops.secrets.nextdns-config.path} &
            nextdns_pid=$!

            # If the tmpfs is not yet mounted, the file watchers won't trigger on change
            # wait4path will exit when the path is mounted
            if ! [ -d /run/secrets.d/ ]; then
              echo "Secrets volume not yet mounted. This script will restart when it is."
              /bin/wait4path /run/secrets.d/ &
            fi

            # Monitor symlink and config file in background
            # fswatch will exit when those paths are modified
            ${pkgs.fswatch}/bin/fswatch -1 ${config.sops.secrets.nextdns-config.path} > /dev/null &

            # Wait for at least one process to exit
            wait -n
            exit_code=$?

            # Check if the nextdns process has exited
            if ! /bin/ps -p $nextdns_pid > /dev/null; then
              echo "Process has exited with code $exit_code. Exiting script."
              exit $exit_code
            fi

            # Kill all other running processes
            echo "A monitored file was changed. Restarting."
            pids=$(jobs -p)
            kill $pids 2> /dev/null
            wait $pids

            # Before restarting the loop, let's sleep for 100 ms
            echo "Restarting in 100 ms..."
            /bin/sleep 0.1
          done
        ''
      )
    );
  };

  # Create sourcings for zsh and fish
  programs.zsh.enable = true;
  programs.fish.enable = true;

  users.users.nik.home = home;

  # Your Terminal emulator might need Full Disk Access to change icons for all applications
  environment.customIcons = {
    enable = true;
    icons = map appicon [
      "calibre"
      "ImageOptim"
      "kitty"
      "LogSeq"
      "Microsoft Excel"
      "Microsoft OneNote"
      "Microsoft Teams"
      "Microsoft Word"
      "Notion"
      "Spotify"
      "Telegram"
      "Visual Studio Code"
    ];
  };

  system.defaults.finder = {
    FXPreferredViewStyle = "Nlsv"; # Always open everything in list view
    ShowStatusBar = true; # Show status bar
    ShowPathbar = true; # Show path bar
    _FXSortFoldersFirst = true; # Keep folders on top when sorting by name
    FXEnableExtensionChangeWarning = false; # Disable the warning when changing a file extension
    FXDefaultSearchScope = "SCcf"; # When performing a search, search the current folder by default
  };

  system.defaults.trackpad = {
    Clicking = true; # Enable tap to click
    TrackpadThreeFingerDrag = true; # Enable three finger drag
  };

  system.defaults.NSGlobalDomain = {
    # Enable key repeat when pressing and holding a key and set a fast repeat rate
    ApplePressAndHoldEnabled = false;
    InitialKeyRepeat = 16;
    KeyRepeat = 2;

    AppleShowAllExtensions = true; # Show all filename extensions in Finder

    AppleSpacesSwitchOnActivate = false; # Disable switching to a space when an application is activated
  };

  system.defaults.dock = {
    autohide = true; # automatically hide and show the Dock
  };

  system.activationScripts.postUserActivation = {
    text = ''
      # Set default shell to fish
      sudo chsh -s /run/current-system/sw/bin/fish nik

      # Disable "Select the previous input source", because I use Ctrl + Space in Tmux
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><false/></dict>'

      # Disable "Show Spotlight search", because I use Cmd + Space for Raycast
      defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'

      # Activate settings so we don't have to restart
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # `zap` will move related files of apps that are removed to the trash
      cleanup = "zap";
      # This will force an overwrite of apps already present
      extraFlags = [ "--force" ];
    };

    taps = [
      # Upgrade casks with `brew cu -a`
      "buo/cask-upgrade"
    ];

    brews = [
      # Although we already have it in home-manager, this gpg binary is the only one that Fork can find
      "gnupg"
      # The Bitwarden CLI is currently broken in nix, so we install it from Brew
      "bitwarden-cli"
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
      "arc" # Chromium based browser
      "audacity" # Cross-platform audio software
      "beeper" # Universal chat app
      "bitwarden" # Desktop password and login vault
      "blackhole-2ch" # Virtual Audio Driver
      "calibre" # E-books management software
      "cyberduck" # Server and cloud storage browser
      "dbngin" # Database version management tool
      "discord" # Voice and text chat software
      "docker" # App to build and share containerised applications and microservices
      "dropbox" # Client for the Dropbox cloud storage service
      "figma" # Collaborative team software
      "finicky" # Utility for customizing which browser to start
      "firefox" # Web browser
      "fork" # GIT client
      "ghostty" # Terminal emulator that uses platform-native UI and GPU acceleration
      "httpie" # Testing client for REST, GraphQL, and HTTP APIs
      "imageoptim" # Tool to optimise images to a smaller size
      "karabiner-elements" # Keyboard customizer
      "kitty" # GPU-based terminal emulator
      "logseq" # Privacy-first, open-source platform for knowledge sharing and management
      "macfuse" # File system integration
      "microsoft-teams" # Team messaging app
      "missive" # Team inbox and chat tool
      "mos" # Smooths scrolling and set mouse scroll directions independently
      "musescore" # Open-source music notation software
      "nota" # Markdown files editor
      "notion-calendar" # Calendar by Notion
      "notion" # App to write, plan, collaborate, and get organised
      "numi" # Calculator and converter application
      "obsidian" # Knowledge base that works on top of a local folder of plain text Markdown files
      "phoenix" # Window and app manager scriptable with JavaScript
      "protonvpn" # VPN client focusing on security
      "proxyman" # HTTP debugging proxy
      "qlmarkdown" # Quick Look generator for Markdown files
      "raycast" # Control your tools with a few keystrokes
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
      "windsurf" # VSCode-fork with AI integration
      "wireshark" # Network protocol analyzer
      "yubico-authenticator" # Application for configuring YubiKeys
      "zoom" # Video communication and virtual meeting platform
    ];
  };

  system.stateVersion = 5;
}
