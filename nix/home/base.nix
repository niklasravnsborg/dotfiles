# Shell, prompt and command-line tools for any machine I log in to.
#
# It needs no secrets and no checkout of this repository, so other flakes can
# import it as `dotfiles.homeModules.base`, e.g. for a server:
#
#   home-manager.users.nik.imports = [ dotfiles.homeModules.base ];
#
# Config files come from the Nix store unless `dotfiles.liveLinks` is on.
# Modules can link further files with the `dotfile` and `dotfilePath` module
# arguments, which follow the same setting.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles;
  configDir = "${config.home.homeDirectory}/dotfiles";

  # Path of a file in this repository, as a string
  dotfilePath = file: if cfg.liveLinks then "${configDir}/${file}" else "${../.. + "/${file}"}";

  # `home.file` entry for a file in this repository
  dotfile = file: {
    source =
      if cfg.liveLinks then
        config.lib.file.mkOutOfStoreSymlink "${configDir}/${file}"
      else
        ../.. + "/${file}";
  };
in
{
  options.dotfiles.liveLinks = lib.mkEnableOption ''
    symlinks into the checkout at ~/dotfiles instead of copies in the Nix store,
    so edits to config files apply without a rebuild
  '';

  imports = [
    ../../tmux/tmux-module.nix
    ../../tmux/tmux.nix
  ];

  config = {
    _module.args = { inherit dotfile dotfilePath; };

    home.packages = with pkgs; [
      any-nix-shell # Run nix-shell in any directory
      btop # Monitor of resources
      delta # Syntax-highlighter for git and diff output
      fd # Alternative to find
      git # Version control system
      gnused # GNU version of the famous stream editor
      gnutar # GNU version of the tar archiving utility
      helix # Post-modern modal text editor
      htop # Improved top (interactive process viewer)
      less # Pager program
      tlrc # client for tldr: collaborative cheatsheets for console commands
      tree # Display directories as trees
      watch # Execute a program periodically
      yq # Process YAML, JSON, XML, CSV and properties documents
    ];

    home.file = {
      ".config/btop/btop.conf" = dotfile "btop/btop.conf";
      ".config/helix/config.toml" = dotfile "helix/config.toml";
      ".config/helix/themes/my_theme.toml" = dotfile "helix/my_theme.toml";
      ".config/starship.toml" = dotfile "starship/starship.toml";
    };

    # This sets the `XDG_CONFIG_HOME` environment variable to `~/.config`.
    # For some programs (e.g. `sops`) on macOS this is needed, because they would otherwise look for their config files in `~/Library/Application Support`.
    xdg.enable = true;

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Disable man cache generation since we're not using a custom man package
    programs.man.generateCaches = false;

    home.shellAliases = {
      # Set the `TERM` env var to fix color display with `delta` as long as lazygit doesn't support Ghostty.
      # Relevant Pull Request: https://github.com/jesseduffield/lazygit/pull/4149
      lg = "TERM=xterm-256color lazygit";
      man = "batman";
      cat = "bat -p";

      # Shortcuts
      c = "clear";
    };

    programs.fish = {
      enable = true;
      shellInitLast = "source ${dotfilePath "fish"}/config.fish";
      plugins = [
        {
          name = "fzf.fish";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "v10.3";
            sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
          };
        }
        {
          name = "sponge";
          src = pkgs.fetchFromGitHub {
            owner = "meaningful-ooo";
            repo = "sponge";
            rev = "1.1.0";
            sha256 = "sha256-MdcZUDRtNJdiyo2l9o5ma7nAX84xEJbGFhAVhK+Zm1w=";
          };
        }
        {
          name = "autopair.fish";
          src = pkgs.fetchFromGitHub {
            owner = "jorgebucaran";
            repo = "autopair.fish";
            rev = "1.0.4";
            sha256 = "sha256-s1o188TlwpUQEN3X5MxUlD/2CFCpEkWu83U9O+wg3VU=";
          };
        }
        {
          name = "grc";
          src = pkgs.fetchFromGitHub {
            owner = "orefalo";
            repo = "grc";
            rev = "68e4325c1f261dfa5153937e7670fde046a0fe56";
            sha256 = "sha256-iHlxCEKYyKHlIpyOz4bwTQ6R0lr7FqZb54/wuWfWQfg=";
          };
        }
        {
          name = "spaced-prompts.fish";
          src = pkgs.fetchFromGitHub {
            owner = "niklasravnsborg";
            repo = "spaced-prompts.fish";
            rev = "0.1.1";
            sha256 = "sha256-J0RdvUwn+r39jNFNus9XYDjwhf8Qh/nZqtRo/BpShh4=";
          };
        }
      ];
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        hide_env_diff = true;
      };
    };

    # Universal prompt
    programs.starship = {
      enable = true;
    };

    # Modern replacement for 'ls'
    programs.eza = {
      enable = true;
      icons = "auto";
      git = true;
      extraOptions = [
        "--classify"
        "--group-directories-first"
        "--header"
        "--group"
        "--created"
        "--modified"
        "--octal-permissions"

        "--time-style"
        "long-iso"
      ];
    };

    # Modern replacement for 'cd'
    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
    };

    # Modern replacement for 'cat'
    programs.bat = {
      enable = true;
      config.theme = "Coldark-Dark";

      extraPackages = with pkgs.bat-extras; [
        batman
      ];
    };

    programs.fzf = {
      enable = true;
      enableFishIntegration = false;
      package = pkgs.fzf.overrideAttrs (oldAttrs: {
        # The normal postInstall script installs shell integrations.
        # I don't want them, because I use the fish plugin `PatrickF1/fzf.fish`.
        postInstall = ''
          install bin/fzf-tmux $out/bin
          installManPage man/man1/fzf.1 man/man1/fzf-tmux.1
        '';
      });
    };

    programs.lazygit = {
      enable = true;
      settings = {
        promptToReturnFromSubprocess = false;
        git = {
          diffRenderers = [
            {
              command = "delta --paging=never";
              colorArg = "always";
            }
          ];
          commit = {
            autoWrapCommitMessage = false;
          };
          autoForwardBranches = "none";
        };
        gui = {
          scrollHeight = 1;
          nerdFontsVersion = 3;
          statusPanelView = "allBranchesLog";
          showCommandLog = false;
          showBottomLine = true;
          theme = {
            authorColors = {
              "*" = "#b7bdf8";
            };
            activeBorderColor = [
              "#ee99a0"
              "bold"
            ];
            inactiveBorderColor = [ "#a5adcb" ];
            optionsTextColor = [ "#8aadf4" ];
            selectedLineBgColor = [ "#363a4f" ];
            cherryPickedCommitBgColor = [ "#494d64" ];
            cherryPickedCommitFgColor = [ "#ee99a0" ];
            unstagedChangesColor = [ "#ed8796" ];
            defaultFgColor = [ "#cad3f5" ];
            searchingActiveBorderColor = [ "#eed49f" ];
          };
        };
        update = {
          method = "never";
        };
      };
    };
  };
}
