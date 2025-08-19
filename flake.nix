{
  description = "Niklas dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/release-24.05";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
    nix-darwin = {
      url = "github:niklasravnsborg/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "nix-darwin";
      inputs.brew-src.url = "github:Homebrew/brew/4.4.25";
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
          overlays = [
            (import ./nix/overlays/claude.nix)
            # bitwarden-cli-2025.3.0 had some build issues
            (final: prev: { bitwarden-cli = inputs.nixpkgs-stable.legacyPackages.${system}.bitwarden-cli; })
          ];
        };
      secretsPath = builtins.toString inputs.dotfiles-secrets;
      homeManagerConfig = {
        useGlobalPkgs = true;
        users.nik = import ./nix/home.nix;
        sharedModules = [
          inputs.sops-nix.homeManagerModules.sops
          ./tmux/tmux-module.nix

        ];
        extraSpecialArgs = {
          inherit secretsPath;
        };
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
              sharedModules = homeManagerConfig.sharedModules ++ [
                ./macos/file-associations
              ];
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
          pkgs = myNixpkgs systems.nixos;
        };
        modules = [
          ./nixos/configuration.nix
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = homeManagerConfig // {
              useUserPackages = true;
            };
          }
        ];
      };

      # Small tool to iterate over each systems
      eachSystem =
        f:
        inputs.nixpkgs.lib.genAttrs (import inputs.systems) (
          system: f inputs.nixpkgs.legacyPackages.${system}
        );

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

    in
    {
      # for `nix fmt`
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      # for `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check inputs.self;
      });

      darwinConfigurations."Barrakuda" = darwinSystem;
      darwinConfigurations."Mantarochen" = darwinSystem;
      nixosConfigurations."Quastenflosser" = nixosSystem;

    };
}
