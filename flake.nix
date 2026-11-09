{
  description = "IaC flake";

  inputs = {
    self.submodules = true;

    # Platform-specific nixpkgs channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin?ref=nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    systems.url = "github:nix-systems/default";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
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

    home-manager.url = "github:nix-community/home-manager?ref=release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Need to use git+ssh to work around: https://github.com/NixOS/nix/issues/13571
    dotfiles.url = "git+ssh://git@github.com/guergeiro/dotfiles.git";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nix-secrets.follows = "nix-secrets";
    dotfiles.inputs.agenix.follows = "agenix";
    dotfiles.inputs.systems.follows = "systems";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";

    git-format-staged.url = "github:hallettj/git-format-staged";
    git-format-staged.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-darwin,
      nix-darwin,
      home-manager,
      dotfiles,
      agenix,
      systems,
      deploy-rs,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      nix-secrets,
      disko,
      preservation,
      git-format-staged,
      ...
    }:
    let
      hosts = builtins.fromJSON (builtins.readFile "${nix-secrets}/hosts.json");

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          let
            pkgs =
              if builtins.match ".*-darwin" system != null then
                nixpkgs-darwin.legacyPackages.${system}
              else
                nixpkgs.legacyPackages.${system};
          in
          function pkgs
        );

      # Read: https://isabelroses.com/blog/im-not-mad-im-disappointed/
      hostSystemModule = (
        { host, ... }: {
          nixpkgs.hostPlatform = host.system;
        }
      );

      configurations = map (
        hostname:
        let
          host = builtins.fromJSON (builtins.readFile "${nix-secrets}/${hostname}/host.json");
          username = host.username;
          envVars = host.environment or { };
          isWorkstation = host.workstation or false;
          baseModules = [
            hostSystemModule
            ./hosts/${hostname}/configuration.nix
          ];
          nixosModules = [
            disko.nixosModules.disko
            preservation.nixosModules.default
          ];
        in
        {
          specialArgs = {
            inherit
              self
              username
              hostname
              host
              nix-secrets
              envVars
              home-manager
              isWorkstation
              dotfiles
              nix-homebrew
              homebrew-core
              homebrew-cask
              agenix
              ;
          };
          modules =
            baseModules ++ (if builtins.match ".*-darwin" host.system == null then nixosModules else [ ]);
        }
      ) hosts;

      linuxWorkstations = builtins.filter (
        machine:
        machine.specialArgs.isWorkstation == true
        && builtins.match ".*-darwin" machine.specialArgs.host.system == null
      ) configurations;
      darwinWorkstations = builtins.filter (
        machine:
        machine.specialArgs.isWorkstation == true
        && builtins.match ".*-darwin" machine.specialArgs.host.system != null
      ) configurations;

      linuxServers = builtins.filter (machine: machine.specialArgs.isWorkstation != true) configurations;

    in
    {
      darwinConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine.specialArgs.hostname;
          value = nix-darwin.lib.darwinSystem {
            specialArgs = machine.specialArgs;
            modules = machine.modules;
          };
        }) darwinWorkstations
      );
      nixosConfigurations = builtins.listToAttrs (
        map (machine: {
          name = machine.specialArgs.hostname;
          value = nixpkgs.lib.nixosSystem {
            specialArgs = machine.specialArgs;
            modules = machine.modules;
          };
        }) (linuxWorkstations ++ linuxServers)
      );

      deploy.nodes = builtins.listToAttrs (
        map (server: {
          name = server.specialArgs.hostname;
          value = {
            hostname = "${server.specialArgs.hostname}.${server.specialArgs.envVars.BASE_DOMAIN}"; # Initially we need the ip address
            profiles.system = {
              sshUser = "root";
              path =
                deploy-rs.lib.${server.specialArgs.host.system}.activate.nixos
                  self.nixosConfigurations.${server.specialArgs.hostname};
            };
          };
        }) linuxServers
      );
      checks =
        (builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib)
        // forAllSystems (pkgs: {
          nix-fmt =
            pkgs.runCommand "check-nix-fmt"
              {
                buildInputs = [ pkgs.nixfmt ];
              }
              ''
                ${pkgs.nixfmt}/bin/nixfmt --check .
                touch $out
              '';

          tofu-fmt =
            pkgs.runCommand "check-tofu-fmt"
              {
                buildInputs = [
                  pkgs.opentofu
                  pkgs.coreutils
                ];
              }
              ''
                ${pkgs.opentofu}/bin/tofu fmt -check -recursive ${./infra}
                ${pkgs.coreutils}/bin/touch $out
              '';

        });

      devShells = forAllSystems (
        pkgs:
        let
          hookScripts = {
            pre-commit = pkgs.writeShellScript "pre-commit" ''
              format_staged_nix_files() {
                git-format-staged -f '${pkgs.nixfmt}/bin/nixfmt --filename {}' '*.nix'
              }

              format_staged_tf_files() {
                git-format-staged -f '${pkgs.opentofu}/bin/tofu fmt {}' '*.tf'
              }

              format_staged_nix_files
              format_staged_tf_files
            '';
            post-commit = pkgs.writeShellScript "post-commit" ''
              exec ${pkgs.git}/bin/git update-index -g
            '';
          };
          hooksEnv = {
            GIT_CONFIG_COUNT = "1";
            GIT_CONFIG_KEY_0 = "core.hooksPath";
            GIT_CONFIG_VALUE_0 = pkgs.linkFarm "git-hooks" (
              pkgs.lib.mapAttrsToList (name: path: {
                inherit name path;
              }) hookScripts
            );
          };

          anywhereScript = pkgs.writeShellScriptBin "nix-anywhere" ''
            ${pkgs.nix}/bin/nix run github:nix-community/nixos-anywhere -- --flake $1 --target-host nixos@$2
          '';
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [ git-format-staged.packages.${pkgs.stdenv.hostPlatform.system}.default ];
            env = hooksEnv;
          };
          root-shell = pkgs.mkShellNoCC {
            inputsFrom = [ self.devShells.${pkgs.stdenv.hostPlatform.system}.default ];

            packages = [
              pkgs.nixfmt
              pkgs.nixd
              pkgs.git-crypt
              anywhereScript
              deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
              agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
            ];

            env = hooksEnv;
          };
          tf-shell = pkgs.mkShellNoCC {
            inputsFrom = [ self.devShells.${pkgs.stdenv.hostPlatform.system}.default ];

            packages = [
              pkgs.opentofu
              # Create a wrapper executable named "terraform" that proxies to opentofu
              (pkgs.writeShellScriptBin "terraform" ''
                exec ${pkgs.opentofu}/bin/tofu "$@"
              '')

              (pkgs.writeShellScriptBin "tf-init" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 init -backend-config=../../env-backend/$1.tfbackend -var-file=../../env-vars/$1.tfvars
              '')
              (pkgs.writeShellScriptBin "tf-validate" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 validate -var-file=../../env-vars/$1.tfvars
              '')
              (pkgs.writeShellScriptBin "tf-plan" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 plan -var-file=../../env-vars/$1.tfvars -out=tfplan
              '')
              (pkgs.writeShellScriptBin "tf-apply" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 apply tfplan
              '')
              (pkgs.writeShellScriptBin "tf-destroy-plan" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 plan -destroy -var-file=../../env-vars/$1.tfvars -out=tfdestroyplan
              '')
              (pkgs.writeShellScriptBin "tf-destroy-apply" ''
                exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 apply tfdestroyplan
              '')
            ];

            env = hooksEnv;
          };
        }
      );
    };
}
