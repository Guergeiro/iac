{
  description = "IaC flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "git+file:../dotfiles";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";

    nix-secrets.url = "git+file:./nix-secrets";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, dotfiles, mac-app-util, nix-homebrew, homebrew-core, homebrew-cask, nix-secrets, ... }@inputs:
  {
    nixosConfigurations."laptop" = nixpkgs.lib.nixosSystem {
      specialArgs = {
        system = "x86_64-linux";
        username = nix-secrets."x86_64-linux".username;
        updateCmd = "sudo nixos-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#laptop";
        inherit inputs;
      };
      modules = [
        ./nixos/configuration.nix
        ./shared/system.nix
        home-manager.nixosModules.home-manager
        ({ pkgs, system, username, ... }:
        let
          dotfilesHmData = dotfiles.homeManagerModules.${system};
        in {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Moved extraSpecialArgs here, making them available to all users in this system
            extraSpecialArgs = dotfilesHmData.extraSpecialArgs;
            users.${username} = {
              imports = dotfilesHmData.modules;
              # No extraSpecialArgs here anymore
            };
          };
        })
      ];
    };
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      specialArgs = {
        system = "aarch64-darwin";
        username = nix-secrets."aarch64-darwin".username;
        updateCmd = "sudo darwin-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#macbook";
        inherit inputs;
      };
      modules = [
        ({ config, ... }: {
          homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
        })
        ./darwin/configuration.nix
        ./shared/system.nix
        mac-app-util.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        # Import Home Manager with dotfiles
        home-manager.darwinModules.home-manager
        ({ pkgs, system, username, ... }:
        let
          dotfilesHmData = dotfiles.homeManagerModules.${system};
        in {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Moved extraSpecialArgs here, making them available to all users in this system
            extraSpecialArgs = dotfilesHmData.extraSpecialArgs;
            users.${username} = {
              imports = dotfilesHmData.modules;
              # No extraSpecialArgs here anymore
            };
          };
        })
        ({username, ...}: {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = username;

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        })
      ];
    };
  };
}
