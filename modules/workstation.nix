{
  inputs,
  pkgs,
  lib,
  hostname,
  host,
  ...
}:
let
  inherit (inputs) self dotfiles home-manager;
  inherit (host) username;

  envVars = host.environment or { };

  darwinUpdateCmd = "sudo darwin-rebuild switch --flake .#${hostname}";
  nixosUpdateCmd = "nixos-rebuild switch --flake .#${hostname} --sudo";

  homeCfg = (
    {
      pkgs,
      hostname,
      ...
    }:
    let
      homeCfg = dotfiles.mkHomeModules pkgs hostname false;
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
in
{
  imports = [
    "${self}/modules/nix.nix"
    "${self}/modules/users.nix"
    "${self}/modules/security.nix"
    (
      if builtins.match ".*-darwin" host.system != null then
        home-manager.darwinModules.home-manager
      else
        home-manager.nixosModules.home-manager
    )
    homeCfg
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
}
