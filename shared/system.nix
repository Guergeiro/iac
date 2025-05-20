{ pkgs, updateCmd, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
    alacritty-theme
    awesome
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
    tmuxPlugins.dracula
    tmuxPlugins.resurrect
    tmuxPlugins.yank
    trash-cli
    vim
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
      options = "--delete-older-than 10d";
    };
  };

  environment.shellAliases = {
    update = "sudo ${updateCmd}";
    upgrade = "sudo nix flake update --flake $HOME/Documents/guergeiro/iac";
    # You remember Vi? It's just faster to type
    vi = "${pkgs.neovim}/bin/nvim";
    vim = "${pkgs.neovim}/bin/nvim";
    # Force tmux UTF-8
    tmux="${pkgs.tmux}/bin/tmux -u";
    # Sometimes I forget I'm not in VIM, but still want to quit :>
    ":q"="exit";
    # Fuck Python2... Sorry :(
    python="python3"; pip="pip3";
    # Security stuff
    del="${pkgs.trash-cli}/bin/trash";
    rm="${pkgs.coreutils}/bin/echo Use \"del\", or the full path i.e. \"/bin/rm\"";
    mv="${pkgs.coreutils}/bin/mv -i";
    cp="${pkgs.coreutils}/bin/cp -i";
    ln="${pkgs.coreutils}/bin/ln -i";
    # Recursively create directories
    mkdir="${pkgs.coreutils}/bin/mkdir -pv";

    # Some more ls aliases
    ll="${pkgs.coreutils}/bin/ls -alhF";
    la="${pkgs.coreutils}/bin/ls -hA";
    l="${pkgs.coreutils}/bin/ls -CF";
    ls="${pkgs.coreutils}/bin/ls --color=auto";

    # Ripgrep rules for me!
    grep="${pkgs.ripgrep}/bin/rg --hidden --color=auto";
    fgrep="${pkgs.ripgrep}/bin/rg -F --color=auto";
    egrep="${pkgs.ripgrep}/bin/rg -E --color=auto";

    # Bat is awesome
    cat="${pkgs.bat}/bin/bat";
  };
}
