{
  flake.nixosModules."mazaltur" =
    {
      pkgs,
      lib,
      config,
      hostname,
      ...
    }:
    let
    in
    {
      systemd.targets."docker-mazaltur-root" = {
        unitConfig = {
          Description = "Root target for mazaltur.";
        };
        wantedBy = [ "multi-user.target" ];
      };

      # Services that start/stop root group
      systemd.services."stop-docker-mazaltur-root" = {
        path = [ pkgs.systemd ];
        description = "Stops the entire mazaltur group.";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl stop docker-mazaltur-root.target";
        };
      };

      systemd.services."start-docker-mazaltur-root" = {
        path = [ pkgs.systemd ];
        description = "Starts the entire cloudflare-tunnel group.";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl start docker-cloudflare-tunnel-root.target";
        };
      };

      # Timers
      systemd.timers."stop-docker-cloudflare-tunnel-root" = {
        description = "Timer to stop the cloudflare-tunnel stack at 4:40 am.";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 04:40:00";
          Unit = "stop-docker-cloudflare-tunnel-root.service";
        };
      };

      systemd.timers."start-docker-cloudflare-tunnel-root" = {
        description = "Timer to start the cloudflare-tunnel stack at 5:00 am.";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 05:00:00";
          Unit = "start-docker-cloudflare-tunnel-root.service";
        };
      };

      systemd.services."docker-cloudflare-tunnel" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
        };
        after = [
          "docker-network-cloudflare-tunnel.service"
        ];
        requires = [
          "docker-network-cloudflare-tunnel.service"
        ];
        partOf = [
          "docker-cloudflare-tunnel-root.target"
        ];
        wantedBy = [
          "docker-cloudflare-tunnel-root.target"
        ];
      };

      virtualisation.oci-containers.containers."cloudflare-tunnel" = {
        image = image;
        imageFile = imageFile;
        cmd = [
          "tunnel"
          "--no-autoupdate"
          "run"
        ];
        environmentFiles = [
          config.age.secrets."orange/cloudflare-tunnel.age".path
        ];
        networks = [
          "cloudflare-tunnel"
        ];
        extraOptions = [
          "--add-host=host.docker.internal:host-gateway"
        ];
      };
    };
}
