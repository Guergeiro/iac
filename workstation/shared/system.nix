{
  self,
  pkgs,
  updateCmd,
  envVars,
  lib,
  ...
}:
{
  imports = [
    "${self}/modules/nix.nix"
    "${self}/modules/users.nix"
    "${self}/modules/security.nix"
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  fonts.packages = [
    pkgs.nerd-fonts.fantasque-sans-mono
  ];

  environment.shellAliases.update = updateCmd;

  environment.variables = lib.mkMerge [
    envVars
  ];
}
