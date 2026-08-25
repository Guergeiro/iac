{
  pkgs,
  lib,
  envVars,
  ...
}:
let
  imageName = "cloudflare/cloudflared";
  imageVersion = "2026.8.2";
  image = "${imageName}:${imageVersion}";
  imageFile = null;
in
{
  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-cloudflare-tunnel-root" = {
    unitConfig = {
      Description = "Root target for cloudflare-tunnel.";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Networks
  systemd.services."docker-network-cloudflare-tunnel" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.docker}/bin/docker network rm -f cloudflare-tunnel";
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect cloudflare-tunnel || \
      ${pkgs.docker}/bin/docker network create --subnet 172.20.0.0/24 cloudflare-tunnel
    '';
    partOf = [ "docker-cloudflare-tunnel-root.target" ];
    wantedBy = [ "docker-cloudflare-tunnel-root.target" ];
  };

  # Services that start/stop root group
  systemd.services."stop-docker-cloudflare-tunnel-root" = {
    path = [ pkgs.systemd ];
    description = "Stops the entire cloudflare-tunnel group.";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl stop docker-cloudflare-tunnel-root.target";
    };
  };

  systemd.services."start-docker-cloudflare-tunnel-root" = {
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
      "--token"
      "${envVars.CLOUDFLARE_TUNNEL_TOKEN}"
    ];
    networks = [
      "cloudflare-tunnel"
    ];
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
    ];
  };
}
