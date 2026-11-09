{
  pkgs,
  config,
  lib,
  llmAgents,
  secretsPath,
  dotfile,
  dotfilePath,
  ...
}:

let
  homePath = config.home.homeDirectory;
  llmAgentPackages = llmAgents.packages.${pkgs.stdenv.hostPlatform.system};
  claudeCode = pkgs.symlinkJoin {
    name = "claude-code-with-node";
    paths = [ llmAgentPackages.claude-code ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --argv0 claude \
        --prefix PATH : ${lib.makeBinPath [ pkgs.nodejs ]}
    '';
  };
in
{
  imports = [ ./base.nix ];

  dotfiles.liveLinks = true;

  home.stateVersion = "26.05";

  home.shellAliases = {
    nix-switch =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "sudo darwin-rebuild switch --flake ~/dotfiles"
      else
        "sudo nixos-rebuild switch --flake ~/dotfiles";
    oc = "opencode";
    svgo = "svgo --config=$HOME/.svgo.config.js";
    ffmpeg = "ffmpeg -hide_banner";

    # Shortcuts
    o = "open .";
    dot = "hx ~/dotfiles";
  };

  home.packages = with pkgs; [
    act # Run GitHub Actions locally
    age # Secure file encryption
    atuin # Universal history
    bun # Incredibly fast JavaScript runtime
    cloc # Count lines of code
    cloudflared # Cloudflare tunnel
    ffmpeg_7 # Play, record, convert, and stream audio and video
    gitui # Terminal ui for git
    httpie # User-friendly HTTP client
    imagemagick # Manipulate images in many formats
    micromamba # Environment manager
    ngrok # Reverse proxy, secure tunnels to localhost
    svgo # Optimize SVGs
    pandoc # Document conversion
    posting # API client for the terminal
    restic # Backup program
    sops # Editor of encrypted files

    # AI Tools
    claudeCode
    llmAgentPackages.clauth
    llmAgentPackages.codex
    llmAgentPackages.opencode

    # Fun
    asciiquarium # Aquarium animation
    cbonsai # Bonsai
    cmatrix # Matrix animation
    cowsay # Talking cow
    lolcat # Rainbow colors
    sl # Steam locomotive
  ];

  home.file = {
    ".env.sh" = dotfile "shell/.env.sh";

    ".finicky.ts" = dotfile "finicky/.finicky.ts";
    ".gitconfig" = dotfile "git/.gitconfig";
    ".gitignore" = dotfile "git/.gitignore";
    ".ssh/config" = dotfile "ssh/config";
    ".svgo.config.js" = dotfile "svgo/.svgo.config.js";
    ".vimrc" = dotfile "vim/.vimrc";

    ".config/atuin/config.toml" = dotfile "atuin/config.toml";
    ".config/ghostty/config" = dotfile "ghostty/config";
    ".config/gitui/key_bindings.ron" = dotfile "gitui/key_bindings.ron";
    ".config/gitui/theme.ron" = dotfile "gitui/theme.ron";
    ".config/herdr/config.toml" = dotfile "herdr/config.toml";
    ".config/kitty/kitty.conf" = dotfile "kitty/kitty.conf";
    ".config/nix/nix.conf" = dotfile "nix/nix.conf";
    ".config/opencode/opencode.jsonc" = dotfile "opencode/opencode.jsonc";
    ".config/opencode/tui.jsonc" = dotfile "opencode/tui.jsonc";
    ".config/opencode/plugin/my-plugins.ts" = dotfile "opencode/plugin/my-plugins.ts";

    ".claude/CLAUDE.md" = dotfile "claude/CLAUDE.md";
    ".claude/settings.json" = dotfile "claude/settings.json";
    ".claude/skills/" = dotfile ".agents/skills/";

    # Posting
    ".config/posting/config.yaml" = dotfile "posting/config.yaml";
    ".local/share/posting/themes/my_theme.yaml" = dotfile "posting/themes/my_theme.yaml";

    ".agents/" = dotfile ".agents/";
    ".codex/AGENTS.md" = dotfile ".agents/AGENTS.md";

    # Yazi
    ".config/yazi/theme.toml" = dotfile "yazi/theme.toml";
    ".config/yazi/yazi.toml" = dotfile "yazi/yazi.toml";
    ".config/yazi/keymap.toml" = dotfile "yazi/keymap.toml";

    # Ableset
    "/Users/nik/Library/Application Support/ableset/custom-styles/styles.css" =
      dotfile "ableset/styles.css";
  };

  sops = {
    defaultSopsFile = "${secretsPath}/secrets.yaml";
    age.keyFile = "${homePath}/.config/sops/age/keys.txt";
    secrets = {
      "atuin/username" = { };
      "atuin/password" = { };
      "atuin/key" = {
        path = "${homePath}/.local/share/atuin/key";
      };
    };
  };

  home.activation = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    copyKeyboardLayout = ''
      mkdir -p ~/Library/Keyboard\ Layouts/
      cp -R ${dotfilePath "macos/niklas.keylayout"} ~/Library/Keyboard\ Layouts/
    '';
    # I would prefer to symlink this file, but macOS seems to ignore symlinks in LaunchAgents
    copyTimematorRestart = "cp -R ${dotfilePath "macos"}/timemator.restart.plist ~/Library/LaunchAgents/";
  };

  programs.fish.shellInitLast = lib.mkAfter "source ${dotfilePath "fish"}/workstation.fish";

  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Set PATH and environment
        source ~/.env.sh
      '')

      (lib.mkAfter ''
        # Ignore commands in history that begin with a space
        # https://dev.to/epranka/hide-the-exported-env-variables-from-the-history-49ni
        export HISTCONTROL=ignorespace

        # Bind Alt+Left and Alt+Right to move between words
        bindkey "^[[1;3C" forward-word
        bindkey "^[[1;3D" backward-word

        # Setup Atuin
        eval "$(ATUIN_NOBIND=true atuin init zsh)"
        bindkey '^a' atuin-search

        # This adds a blank line before each command output for better readability
        function precmd { echo }
      '')
    ];

    antidote = {
      enable = true;
      plugins = [
        "wintermi/zsh-gcloud"
      ];
    };
  };

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = ../../gpg/niklasravnsborg.asc;
        trust = 5;
      }
    ];
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package =
      if pkgs.stdenv.hostPlatform.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-curses;
  };

  programs.yazi = {
    enable = true;
    plugins = {
      inherit (pkgs.yaziPlugins)
        full-border
        starship
        ;
    };
    initLua = ''
      require("full-border"):setup()
      require("starship"):setup()
    '';
  };

  # GitHub command-line tool
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
      };
    };
    extensions = [
      # Inline PR review comments: list, reply to and resolve review threads
      pkgs.gh-pr-review
    ];
  };

  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:escape" ];
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ "<Control><Super>Return" ];
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Control><Super>Left" ];
      toggle-tiled-right = [ "<Control><Super>Right" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      # This is the shortcut to lock the screen
      screensaver = [ "<Control><Alt>q" ];
    };

  };
}
