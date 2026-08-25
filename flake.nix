{
  description = "IaC flake";

  inputs = {
    self.submodules = true;

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    qtile-nixpkgs.url = "github:nixos/nixpkgs?ref=83b8ff5ad36094db6f339a8151cade8f01caaa0d";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    systems.url = "github:nix-systems/default";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-secrets = {
      url = "./nix-secrets";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Need to use git+ssh to work around: https://github.com/NixOS/nix/issues/13571
    dotfiles.url = "git+ssh://git@github.com/guergeiro/dotfiles.git";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nix-secrets.follows = "nix-secrets";
    dotfiles.inputs.systems.follows = "systems";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";
  };

  outputs =
    {
      self,
      nixpkgs,
      qtile-nixpkgs,
      nix-darwin,
      home-manager,
      dotfiles,
      systems,
      deploy-rs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      nix-secrets,
      disko,
      preservation,
      ...
    }:
    let
      hosts = builtins.fromJSON (builtins.readFile "${nix-secrets}/hosts.json");

      forAllSystems =
        function: nixpkgs.lib.genAttrs (import systems) (system: function nixpkgs.legacyPackages.${system});

      specialArgs = hostname: updateCmd: {
        username = hosts.${hostname}.username;
        envVars = hosts.${hostname}.environment or { };
        qtileNixpkgs = qtile-nixpkgs.legacyPackages.${hosts.${hostname}.system};
        inherit
          self
          hostname
          updateCmd
          ;
      };

      # Read: https://isabelroses.com/blog/im-not-mad-im-disappointed/
      hostSystemModule = (
        { hostname, ... }: {
          nixpkgs.hostPlatform = hosts.${hostname}.system;
        }
      );

      homeCfg = (
        {
          pkgs,
          hostname,
          username,
          ...
        }:
        let
          homeCfg = dotfiles.mkHomeModules pkgs hostname hosts nix-secrets dotfiles;
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
        hostSystemModule
        home-manager.nixosModules.home-manager
        homeCfg
      ];
      darwinModules = [
        ./workstation/darwin/configuration.nix
        ./workstation/shared/system.nix
        hostSystemModule
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
            hostname = "mango";
            updateCmd = "sudo nixos-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#${hostname}";
          in
          {
            specialArgs = specialArgs hostname updateCmd;
            modules = linuxModules;
          }
        )
      ];

      darwinMachines = [
        (
          let
            hostname = "macbook";
            updateCmd = "sudo darwin-rebuild switch --flake $HOME/Documents/guergeiro/iac/.#${hostname}";
          in
          {
            specialArgs = specialArgs hostname updateCmd;
            modules = darwinModules;
          }
        )
      ];

      linuxServers = [
        (
          let
            hostname = "orange";
            username = hosts.${hostname}.username;
            publicSshKey = builtins.readFile "${nix-secrets}/id_ed25519.pub";
            envVars = hosts.${hostname}.environment or { };
          in
          {
            specialArgs = {
              inherit
                self
                username
                hostname
                publicSshKey
                envVars
                ;
            };
            modules = [
              disko.nixosModules.disko
              preservation.nixosModules.default
              ./servers/${hostname}/configuration.nix
              ./servers/${hostname}/preservation.nix
              ./servers/${hostname}/cloudflare-tunnel.nix
              ./servers/${hostname}/homeassistant.nix
              hostSystemModule
            ];
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
        }) (linuxMachines ++ linuxServers)
      );

      deploy.nodes = builtins.listToAttrs (
        map (server: {
          name = server.specialArgs.hostname;
          value = {
            hostname = "${server.specialArgs.hostname}.${server.specialArgs.envVars.BASE_DOMAIN}"; # Initially we need the ip address
            profiles.system = {
              sshUser = "root";
              path =
                deploy-rs.lib.${hosts.${server.specialArgs.hostname}.system}.activate.nixos
                  self.nixosConfigurations.${server.specialArgs.hostname};
            };
          };
        }) linuxServers
      );
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

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
          anywhereScript = pkgs.writeShellScriptBin "nix-anywhere" ''
            ${pkgs.nix}/bin/nix run github:nix-community/nixos-anywhere -- --flake $1 --target-host nixos@$2
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixfmt
              pkgs.nixd
              pkgs.git-crypt
              pkgs.deploy-rs
              anywhereScript
            ];

            GIT_CONFIG_COUNT = "1";
            GIT_CONFIG_KEY_0 = "core.hooksPath";
            GIT_CONFIG_VALUE_0 = hooksDir;
          };
        }
      );
    };
}
