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
in
{
  flake.nixosModules.workstation =
    {
      pkgs,
      lib,
      host,
      hostname,
      ...
    }:
    let
      inherit (host) username;
      envVars = host.environment or { };

      darwinUpdateCmd = "sudo darwin-rebuild switch --flake .#${hostname}";
      nixosUpdateCmd = "nixos-rebuild switch --flake .#${hostname} --sudo";
    in
    {
      imports = [
        self.nixosModules.nix
        self.nixosModules.users
        self.nixosModules.security

        home-manager.nixosModules.home-manager
        (createHomeManagerConfig username hostname host)
      ];

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

  flake.darwinModules.workstation =
    {
      pkgs,
      lib,
      host,
      hostname,
      ...
    }:
    let
      inherit (host) username;
      envVars = host.environment or { };

      darwinUpdateCmd = "sudo darwin-rebuild switch --flake .#${hostname}";
      nixosUpdateCmd = "nixos-rebuild switch --flake .#${hostname} --sudo";
    in
    {
      imports = [
        self.darwinModules.nix
        self.darwinModules.users
        self.darwinModules.security

        home-manager.darwinModules.home-manager
        (createHomeManagerConfig username hostname host)
      ];

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
}
