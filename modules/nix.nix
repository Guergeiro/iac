{ pkgs, lib, ... }:
{
  # Necessary for using flakes on this system.
  nix = {
    settings.experimental-features = "nix-command flakes";
    optimise.automatic = true;
    gc = lib.mkMerge [
      {
        automatic = true;
        options = "--delete-older-than 5d";
      }
      (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        dates = "daily";
      })
      (lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        interval = {
          Hour = 0;
          Minute = 0;
        };
      })
    ];
    # Automatically free whenever less than 1GB remaining
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
    '';
  };
}
