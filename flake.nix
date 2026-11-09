{
  description = "Niklas dotfiles";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
    llm-agents.url = "github:numtide/llm-agents.nix";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.url = "github:Homebrew/brew/7.0.13";
    };
    nix-darwin-custom-icons = {
      url = "github:ryanccn/nix-darwin-custom-icons";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dotfiles-secrets = {
      url = "git+ssh://git@github.com/niklasravnsborg/dotfiles-secrets?shallow=1";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      systems = {
        darwin = "aarch64-darwin";
        nixos = "x86_64-linux";
      };
      myNixpkgs =
        system:
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      secretsPath = toString inputs.dotfiles-secrets;
      # Full home config with secrets, for machines I work on
      workstationModule = {
        imports = [
          ./nix/home/workstation.nix
          inputs.sops-nix.homeManagerModules.sops
        ];
        _module.args = {
          inherit secretsPath;
          llmAgents = inputs.llm-agents;
        };
      };
      homeManagerConfig = {
        useGlobalPkgs = true;
        users.nik = workstationModule;
      };
      darwinSystem = inputs.nix-darwin.lib.darwinSystem {
        system = systems.darwin;
        specialArgs = {
          inherit secretsPath;
          pkgs = myNixpkgs systems.darwin;
        };
        modules = [
          ./nix/darwin.nix
          inputs.sops-nix.darwinModules.sops
          inputs.nix-darwin-custom-icons.darwinModules.default
          inputs.home-manager.darwinModules.home-manager
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            home-manager = homeManagerConfig // {
              sharedModules = [ ./macos/file-associations ];
            };
            nix-homebrew = {
              enable = true;
              user = "nik";
            };
          }
        ];
      };
      nixosSystem = inputs.nixpkgs.lib.nixosSystem {
        system = systems.nixos;
        specialArgs = {
          inherit secretsPath;
        };
        modules = [
          ./nixos/configuration.nix
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            nixpkgs.config.allowUnfree = true;
            home-manager = homeManagerConfig // {
              useUserPackages = true;
              sharedModules = [ ./nixos/gnome.nix ];
            };
          }
        ];
      };

      # Small tool to iterate over each system
      eachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs (import inputs.systems) (
          system: f inputs.nixpkgs.legacyPackages.${system}
        );

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

    in
    {
      # Shell, prompt and CLI tools for other flakes, see nix/home/base.nix
      homeModules.base = ./nix/home/base.nix;

      # Everything above plus AI tools and secrets, for other flakes, e.g. a VM:
      #
      #   home-manager.users.nik.imports = [ dotfiles.homeModules.workstation ];
      #
      # Needs an age key at ~/.config/sops/age/keys.txt that is listed in dotfiles-secrets.
      homeModules.workstation = workstationModule;

      # for `nix fmt`
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

      # for `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check inputs.self;
      });

      # development environment, enabled via `.envrc`
      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            nixd
            nixfmt
          ];
        };
      });

      darwinConfigurations."Barrakuda" = darwinSystem;
      darwinConfigurations."Mantarochen" = darwinSystem;
      nixosConfigurations."Quastenflosser" = nixosSystem;

    };
}
