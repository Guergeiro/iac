{ pkgs, updateCmd, ... }:
{
  environment.systemPackages = with pkgs; [
    alacritty
    alacritty-theme
    ansible
    bashInteractive
    bash-completion
    bat
    coreutils
    curl
    deno
    direnv
    docker
    gcc
    git
    neovim
    nix-direnv
    nodejs_22
    librewolf
    openssh
    ripgrep
    starship
    stow
    gnutar
    tmux
    trash-cli
    vim

    bruno
    spotify
  ];

  environment.shells = [
    pkgs.bashInteractive
  ];

  fonts.packages = [
    pkgs.nerd-fonts.fantasque-sans-mono
  ];

  # Necessary for using flakes on this system.
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
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

  environment.shellAliases = {
    update = updateCmd;
    upgrade = "sudo nix flake update --flake $HOME/Documents/guergeiro/iac";
  };

  environment.variables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
    MANPAGER="sh -c 'col -bx | ${pkgs.bat}/bin/bat -l man -p'";
  };
}
