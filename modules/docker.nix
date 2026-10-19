{ username, ... }:
{
  users.users.${username}.extraGroups = [ "docker" ];

  virtualisation.containers.enable = true;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings = {
      live-restore = true;
      ipv6 = true;
      ip-forward-no-drop = true;
    };
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
  virtualisation.oci-containers.backend = "docker";
}
