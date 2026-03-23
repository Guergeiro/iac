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

      # Define forAllSystems to generate Nixpkgs instances for each system
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-darwin"
        ] (system: function nixpkgs.legacyPackages.${system});

      specialArgs = system: hostname: updateCmd: {
        username = secrets.${system}.username;
        envVars = secrets.${system}.environment or { };
        inherit
          self
          system
          hostname
          updateCmd
          ;
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

      linuxModules = [
        ./workstation/nixos/configuration.nix
        ./workstation/shared/system.nix
        home-manager.nixosModules.home-manager
        homeCfg
      ];
      darwinModules = [
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

      linuxMachines = [
        (
          let
            system = "x86_64-linux";
            hostname = "mango";
            updateCmd = "sudo nixos-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#${hostname}";
          in
          {
            specialArgs = specialArgs system hostname updateCmd;
            modules = linuxModules;
          }
        )
      ];

      darwinMachines = [
        (
          let
            system = "aarch64-darwin";
            hostname = "macbook";
            updateCmd = "sudo darwin-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#${hostname}";
          in
          {
            specialArgs = specialArgs system hostname updateCmd;
            modules = darwinModules;
          }
        )
      ];
    in
    {
      darwinConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine.specialArgs.hostname;
          value = nix-darwin.lib.darwinSystem {
            specialArgs = machine.specialArgs;
            modules = machine.modules;
          };
        }) darwinMachines
      );
      nixosConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine.specialArgs.hostname;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = machine.specialArgs;
            modules = machine.modules;
          };
        }) linuxMachines
      );

      devShells = forAllSystems (
        pkgs:
        let
          hookScripts = {
            pre-commit = pkgs.writeShellScript "pre-commit" ''
              format_staged_nix_files() {
                files=$(${pkgs.git}/bin/git diff --cached --name-only --diff-filter=ACMR -- '*.nix')
                [ -z "$files" ] && return 0
                ${pkgs.coreutils}/bin/echo "$files" | ${pkgs.findutils}/bin/xargs ${pkgs.nixfmt}/bin/nixfmt
                ${pkgs.coreutils}/bin/echo "$files" | ${pkgs.findutils}/bin/xargs ${pkgs.git}/bin/git add
              }
              format_staged_nix_files
            '';
            post-commit = pkgs.writeShellScript "post-commit" ''
              exec ${pkgs.git}/bin/git update-index -g
            '';
          };
          hooksDir = pkgs.linkFarm "git-hooks" (
            pkgs.lib.mapAttrsToList (name: path: {
              inherit name path;
            }) hookScripts
          );
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixfmt
            ];

            GIT_CONFIG_COUNT = "1";
            GIT_CONFIG_KEY_0 = "core.hooksPath";
            GIT_CONFIG_VALUE_0 = hooksDir;
          };
        }
      );
    };
}
