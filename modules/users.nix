{ pkgs, username, ... }:
{
  environment.shells = [
    pkgs.bashInteractive
  ];

  users.users.${username} = {
    shell = pkgs.bashInteractive;
    home = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${username}" else "/home/${username}";
  };

  programs.zsh.enable = true;
  programs.bash.completion.enable = true;

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
    zip
    unzip
  ];
}
