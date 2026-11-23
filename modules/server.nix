{ ... }:
{
  flake.nixosModules.server =
    {
      pkgs,
      lib,
      hostname,
      host,
      ...
    }:
    let
      envVars = host.environment or { };
    in
    {
      nix.settings.trusted-users = [ "root" ];

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
        description = "Timer to reboot the system at 4:55 am.";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:55:00";
          Unit = "scheduled-reboot.service";
          Persistent = true;
        };
      };

      networking.hostName = hostname;

      networking.firewall.enable = true;
      networking.dhcpcd.enable = true;
    };
}
