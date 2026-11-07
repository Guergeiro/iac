{
  self,
  pkgs,
  envVars,
  lib,
  hostname,
  hosts,
  home-manager,
  host,
  dotfiles,
  nix-secrets,
  ...
}:
let
  darwinUpdateCmd = "sudo darwin-rebuild switch --flake .#${hostname}";
  nixosUpdateCmd = "nixos-rebuild switch --flake .#${hostname} --sudo";

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
