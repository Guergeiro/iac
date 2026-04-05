{
  pkgs,
  updateCmd,
  username,
  envVars,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    deno
    docker
    gcc
    nodejs
    openssh
    openssl
    python3
    gnutar
    vim
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.shells = [
    pkgs.bashInteractive
  ];

  users.users.${username} = {
    shell = pkgs.bashInteractive;
    home = if pkgs.stdenv.isDarwin then "/Users/${username}" else "/home/${username}";
  };

  programs.zsh.enable = true;
  programs.bash.completion.enable = true;
  programs.tmux.enable = true;

  fonts.packages = [
    pkgs.nerd-fonts.fantasque-sans-mono
  ];

  # Necessary for using flakes on this system.
  nix = {
    settings.experimental-features = "nix-command flakes";
    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 5d";
    };
    # Automatically free whenever less than 1GB remaining
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
    '';
  };

  environment.shellAliases.update = updateCmd;

  environment.variables = lib.mkMerge [
    envVars
  ];
}
