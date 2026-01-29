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

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dotfiles.url = "github:guergeiro/dotfiles";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nix-secrets.follows = "nix-secrets";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-secrets = {
      url = "git+file:./nix-secrets";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      dotfiles,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      nix-secrets,
      disko,
      ...
    }@inputs:
    let
      secrets = builtins.fromJSON (builtins.readFile "${nix-secrets}/vars.json");

      specialArgs = system: {
        system = system;
        username = secrets.${system}.username;
        inherit self;
      };

      homeCfg = (
        {
          pkgs,
          system,
          username,
          ...
        }:
        let
          homeCfg = dotfiles.mkHomeModules pkgs system secrets nix-secrets dotfiles;
        in
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = homeCfg.extraSpecialArgs;
            users.${username}.imports = homeCfg.modules;
          };
        }
      );

      machines = [
        (
          let
            hostname = "mango";
            system = "x86_64-linux";
          in
          {
            specialArgs = {
              updateCmd = "sudo nixos-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#${hostname}";
              username = secrets.${system}.username;
              inherit self system hostname;
            };
            modules = [
              ./workstation/nixos/configuration.nix
              ./workstation/shared/system.nix
              home-manager.nixosModules.home-manager
              homeCfg
            ];
          }
        )
      ];
    in
    {
      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        specialArgs = specialArgs "aarch64-darwin" // {
          updateCmd = "sudo darwin-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#macbook";
        };
        modules = [
          ./workstation/darwin/configuration.nix
          ./workstation/shared/system.nix
          home-manager.darwinModules.home-manager
          homeCfg
          (
            { config, ... }:
            {
              homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
            }
          )
          nix-homebrew.darwinModules.nix-homebrew
          (
            { username, ... }:
            {
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
            }
          )
        ];
      };
      nixosConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine.specialArgs.hostname;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = machine.specialArgs;
            modules = machine.modules;
          };
        }) machines
      );
    };
}
