{
  pkgs,
  username,
  publicSshKey,
  lib,
  envVars,
  ...
}:
{
  nix.settings.trusted-users = [ "root" ];

  users.users.root = {
    openssh.authorizedKeys.keys = [
      publicSshKey
    ];
  };
  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      publicSshKey
    ];
  };
  users.mutableUsers = false;

  environment.variables = lib.mkMerge [
    envVars
  ];

  # Reboot the system everyday
  systemd.services."scheduled-reboot" = {
    path = [ pkgs.systemd ];
    description = "Reboots the system.";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };
  systemd.timers."scheduled-reboot" = {
    description = "Timer to reboot the system at 4:50 am.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:50:00";
      Unit = "scheduled-reboot.service";
      Persistent = true;
    };
  };
}
