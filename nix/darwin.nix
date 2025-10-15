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
  configDir = "${home}/dotfiles";
  appicon = name: {
    path = "/Applications/${name}.app";
    icon = "${configDir}/macos/icons/${name}.icns";
  };
in
{
  # Disable management of the nix installation via nix-darwin since I'm using Determinate Nix
  nix.enable = false;

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
  # Manually start and stop the nextdns service with:
  # `sudo launchctl bootout system /Library/LaunchDaemons/org.nixos.nextdns.plist`
  # `sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.nextdns.plist`
  launchd.daemons.nextdns = {
    # Uncomment to enable logging
    # serviceConfig.StandardErrorPath = "/var/log/nextdns.log";
    # serviceConfig.StandardOutPath = "/var/log/nextdns.log";
    command = mkForce (
      toString (
        pkgs.writeShellScript "nextdns-config-watch" ''
          trap 'kill $(jobs -p); exit' SIGINT

          # `nextdns activate` depends on `launchctl` and `networksetup`
          export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

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
            elif ! [ -e /run/secrets/ ]; then
              echo "Secrets not yet created. Restart the script."
              exit &
            else
              # Monitor symlink and config file in background
              # fswatch will exit when those paths are modified
              ${pkgs.fswatch}/bin/fswatch -1 ${config.sops.secrets.nextdns-config.path} > /dev/null &
            fi

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
      "Spotify"
      "Telegram"
      "Visual Studio Code"
    ];
  };

  system.primaryUser = "nik";

  # Enable Touch ID for sudo
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true; # Fixes Touch ID for sudo inside tmux and screen
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

  system.activationScripts.activateNik = {
    text = ''
      # Set default shell to fish
      sudo chsh -s /run/current-system/sw/bin/fish nik

      # Create a script with proper Nix variable expansion for all user commands
      script="
        # Disable 'Select the previous input source', because I use Ctrl + Space in Tmux
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '<dict><key>enabled</key><false/></dict>'

        # Disable 'Show Spotlight search', because I use Cmd + Space for Raycast
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/></dict>'

        # Activate settings so we don't have to restart
        /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

        # Install keyboard shortcuts
        ${pkgs.bun}/bin/bun run --cwd=${configDir}/macos/karabiner/ build
        ${pkgs.bun}/bin/bun run --cwd=${configDir}/macos/phoenix/ build

        # Configure Final Cut to enable timeline rendering during playback
        defaults write com.apple.FinalCut FFSuspendBGOpsDuringPlay 0

        # Configure Apple Mail
        defaults write com.apple.mail ShowCcHeader 0
        defaults write com.apple.mail EnableContactPhotos 1
        defaults write com.apple.mail NSFont SFPro-Regular
        defaults write com.apple.mail NSFontSize 12

        # Disable autoupgrade - Use `brew cu -aqy` to upgrade apps
        defaults write com.DanPristupov.Fork SUEnableAutomaticChecks -bool false
        defaults write com.seriflabs.affinitydesigner2 AutoUpdateInterval -bool false
        defaults write com.seriflabs.affinityphoto2 AutoUpdateInterval -bool false
        defaults write com.proxyman.NSProxy isUsingSystemStatusBar -bool false
        defaults write com.proxyman.NSProxy shouldShowUpdatePopup -bool false
      "

      # Run the script as user nik
      sudo -u nik bash -c "$script"
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
      # Upgrade casks with `brew cu -aqy`
      "buo/cask-upgrade"
    ];

    brews = [
      # Although we already have it in home-manager, this gpg binary is the only one that Fork can find
      "gnupg"
    ];

    casks = [
      # Fonts
      "font-dm-sans"
      "font-inter"
      "font-kumbh-sans"
      "font-lexend"
      "font-montserrat"
      "font-open-sans"
      "font-palanquin"
      "font-poppins"
      "font-roboto"
      "font-sf-pro"
      "font-source-sans-3"
      "font-space-grotesk"

      # Nerd Fonts
      "font-anonymous-pro"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "font-sauce-code-pro-nerd-font"

      # Applications
      "adobe-digital-editions" # E-book verifier and reader
      "beeper" # Universal chat app
      "bitwarden" # Desktop password and login vault
      "calibre" # E-books management software
      "chatgpt" # ChatGPT macOS app
      "chatwise" # AI chat app
      "deskpad" # A virtual monitor for screen sharing
      "dropbox" # Client for the Dropbox cloud storage service
      "iina" # Multimedia player
      "karabiner-elements" # Keyboard customizer
      "legcord" # Discord client
      "macfuse" # File system integration
      "numi" # Calculator and converter application
      "opensuperwhisper" # Whisper client for macOS
      "phoenix" # Window and app manager scriptable with JavaScript
      "protonvpn" # VPN client focusing on security
      "qlmarkdown" # Quick Look generator for Markdown files
      "raycast" # Control your tools with a few keystrokes
      "rwts-pdfwriter" # Print driver for printing documents directly to a pdf file
      "scroll-reverser" # Set mouse scroll directions independently
      "signal" # Instant messaging application focusing on security
      "spotify" # Music streaming service
      "stats" # System monitor for the menu bar
      "telegram" # Messaging app with a focus on speed and security
      "the-unarchiver" # Unpacks archive files
      "timemator" # Automatic time-tracking application
      "topnotch" # Utility to hide the notch
      "yubico-authenticator" # Application for configuring YubiKeys
      "zoom" # Video communication and virtual meeting platform

      # Web browser
      "arc" # Chromium based browser
      "finicky" # Utility for customizing which browser to start
      "firefox" # Web browser
      "helium-browser" # Chromium based browser
      "ungoogled-chromium" # Chromium based browser with privacy in mind

      # Graphic & Image Applications
      "affinity-designer" # Professional graphic design software
      "affinity-photo" # Professional image editing software
      "figma" # Collaborative team software
      "imageoptim" # Tool to optimise images to a smaller size

      # Audio & Music Applications
      "ableset" # Live setlist manager for Ableton
      "ableton-live-standard" # Music production software
      "audacity" # Cross-platform audio software
      "blackhole-2ch" # Virtual Audio Driver
      "motu-m-series" # Driver for Motu M-Series audio interfaces
      "musescore" # Open-source music notation software
      "native-access" # Installer for Native Instruments products

      # Audio Plugins
      "fabfilter-pro-q" # Equalizer
      "fabfilter-pro-l" # Limiter
      "fabfilter-pro-c" # Compressor
      "fabfilter-pro-mb" # Multi-band compressor
      "fabfilter-saturn" # Saturation
      "youlean-loudness-meter" # Loudness Meter
      "tdr-prism" # Frequency analyzer

      # Productivity
      "anytype" # Local-first and end-to-end encrypted notes app
      "craft" # Personal knowledge management
      "missive" # Team inbox and chat tool
      "nota" # Markdown files editor
      "notion-calendar" # Calendar by Notion
      "notion" # App to write, plan, collaborate, and get organised
      "obsidian" # Knowledge base that works on top of a local folder of plain text Markdown files
      "raindropio" # Bookmark manager

      # Development
      "bruno" # API Client
      "cyberduck" # Server and cloud storage browser
      "dbngin" # Database version management tool
      "fork" # GIT client
      "ghostty" # Terminal emulator that uses platform-native UI and GPU acceleration
      "httpie-desktop" # Testing client for REST, GraphQL, and HTTP APIs
      "kitty" # GPU-based terminal emulator
      "orbstack" # Replacement for Docker Desktop
      "proxyman" # HTTP debugging proxy
      "tableplus" # Native GUI tool for relational databases
      "tuple" # Remote pair programming app
      "visual-studio-code" # Open-source code editor
      "warp" # Rust-based terminal
      "windsurf" # VSCode-fork with AI integration
      "wireshark-app" # Network protocol analyzer
    ];
  };

  system.stateVersion = 5;
}
