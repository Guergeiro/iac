{ inputs, ... }:
let
  inherit (inputs) self dotfiles home-manager;

  standalone = false;

  createHomeManagerConfig = username: hostname: host: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit
          hostname
          host
          standalone
          ;
      };
      users.${username}.imports = [
        dotfiles.homeModules.home
      ];
    };
  };

  createSharedWorkstationConfig =
    pkgs: lib: host: hostname:
    let
      darwinUpdateCmd = "sudo darwin-rebuild switch --flake .#${hostname}";
      nixosUpdateCmd = "nixos-rebuild switch --flake .#${hostname} --sudo";

      envVars = host.environment or { };
    in
    {
      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;

      fonts.packages = [
        pkgs.nerd-fonts.fantasque-sans-mono
      ];

      environment.shellAliases.update =
        if pkgs.stdenv.hostPlatform.isDarwin then darwinUpdateCmd else nixosUpdateCmd;

      environment.variables = lib.mkMerge [
        envVars
      ];
    };
in
{
  flake.nixosModules.workstation =
    {
      host,
      hostname,
      ...
    }:
    let
      inherit (host) username;
    in
    {
      imports = [
        self.nixosModules.nix
        self.nixosModules.users
        self.nixosModules.security
        self.nixosModules.shared-workstation-config

        home-manager.nixosModules.home-manager
        (createHomeManagerConfig username hostname host)
      ];
    };

  flake.darwinModules.workstation =
    {
      host,
      hostname,
      ...
    }:
    let
      inherit (host) username;
    in
    {
      imports = [
        self.darwinModules.nix
        self.darwinModules.users
        self.darwinModules.security
        self.darwinModules.shared-workstation-config

        home-manager.darwinModules.home-manager
        (createHomeManagerConfig username hostname host)
      ];
    };

  flake.nixosModules.shared-workstation-config =
    {
      pkgs,
      lib,
      host,
      hostname,
      ...
    }:
    createSharedWorkstationConfig pkgs lib host hostname;
  flake.darwinModules.shared-workstation-config =
    {
      pkgs,
      lib,
      host,
      hostname,
      ...
    }:
    createSharedWorkstationConfig pkgs lib host hostname;
}
