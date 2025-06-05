{ pkgs, username, ... }:

{
  users.users.${username} = {
    shell = pkgs.bashInteractive;
  };

  programs.bash = {
    completion.enable = true;
  };
}

