{
  lib,
  pkgs,
  ...
}:
let
  imageName = "guergeiro/homeassistant-hacs";
  imageVersion = "2026.8.3";
  image = "${imageName}:${imageVersion}";
  imageFile = null;

  rootDir = "/root/homeassistant";

  haConfig = pkgs.writeText "configuration.yaml" ''
    # Loads default set of integrations. Do not remove.
    default_config:

    homeassistant:
      auth_providers:
        - type: homeassistant
        - type: trusted_networks
          trusted_networks:
            - 127.0.0.1
            - ::1
            - 192.168.32.0/24 # Host network
            - 172.20.0.0/24 # Docker network ipam_config

      allowlist_external_dirs:
        - "/media" # Integration output files
    frontend:
      themes: !include_dir_merge_named themes

    automation: !include automations.yaml
    scene: !include scenes.yaml
    script: !include scripts.yaml
    input_number: !include input_number.yaml
    template: !include templates.yaml
    counter: !include counter.yaml
    camera: !include cameras.yaml
    sensor: !include sensors.yaml
    notify: !include notifications.yaml
    tts: !include tts.yaml
    wake_on_lan:
    backup:
  '';

  systemdServices = [
    "homeassistant"
  ];

  commonServiceConfig = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "upsert-homeassistant-config.service"
      "docker-network-cloudflare-tunnel.service"
      "docker-network-homeassistant.service"
    ];
    requires = [
      "upsert-homeassistant-config.service"
      "docker-network-cloudflare-tunnel.service"
      "docker-network-homeassistant.service"
    ];
    partOf = [
      "docker-cloudflare-tunnel-root.target"
      "docker-homeassistant-root.target"
    ];
    wantedBy = [
      "docker-cloudflare-tunnel-root.target"
      "docker-homeassistant-root.target"
    ];
  };
in
{
  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-homeassistant-root" = {
    unitConfig = {
      Description = "Root target for homeassistant.";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Networks
  systemd.services."docker-network-homeassistant" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.docker}/bin/docker network rm -f homeassistant";
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect homeassistant || \
      ${pkgs.docker}/bin/docker network create homeassistant
    '';
    partOf = [ "docker-homeassistant-root.target" ];
    wantedBy = [ "docker-homeassistant-root.target" ];
  };

  # Services that start/stop root group
  systemd.services."stop-docker-homeassistant-root" = {
    path = [ pkgs.systemd ];
    description = "Stops the entire Homeassisntant group.";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl stop docker-homeassistant-root.target";
    };
  };

  systemd.services."start-docker-homeassistant-root" = {
    path = [ pkgs.systemd ];
    description = "Starts the entire Homeassisntant group.";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start docker-homeassistant-root.target";
    };
  };

  # Timers
  systemd.timers."stop-docker-homeassistant-root" = {
    description = "Timer to stop the Homeassisntant stack at 4:40 am.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:40:00";
      Unit = "stop-docker-homeassistant-root.service";
    };
  };

  systemd.timers."start-docker-homeassistant-root" = {
    description = "Timer to start the Homeassisntant stack at 5:00 am.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 05:00:00";
      Unit = "start-docker-homeassistant-root.service";
    };
  };

  systemd.services."docker-homeassistant" = commonServiceConfig;

  preservation.preserveAt."/persistent" = {
    directories = [
      rootDir
    ];
  };

  systemd.tmpfiles.rules = map (file: "f ${rootDir}/config/${file} 0640 root root -") [
    "automations.yaml"
    "scenes.yaml"
    "scripts.yaml"
    "input_number.yaml"
    "templates.yaml"
    "counter.yaml"
    "cameras.yaml"
    "sensors.yaml"
    "notifications.yaml"
    "tts.yaml"
  ];

  systemd.services."upsert-homeassistant-config" = {
    description = "Enforce Home Assistant configuration.yaml from Nix store";
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p ${rootDir}/config
      ${pkgs.coreutils}/bin/cp -f ${haConfig} ${rootDir}/config/configuration.yaml;
      ${pkgs.coreutils}/bin/chmod 0640 ${rootDir}/config/configuration.yaml;
    '';
    partOf = [ "docker-homeassistant-root.target" ];
    wantedBy = [ "docker-homeassistant-root.target" ];
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  virtualisation.oci-containers.containers."homeassistant" = {
    image = image;
    imageFile = imageFile;
    volumes =
      (map (folder: "${rootDir}/${folder}:/${folder}") [
        "config"
        "media"
      ])
      ++ [
        "/run/udev:/run/udev:ro"
      ];
    dependsOn = builtins.filter (service: service != "homeassistant") systemdServices;
    environment = {
      DISABLE_JEMALLOC = "true";
    };
    capabilities = {
      NET_ADMIN = true;
      NET_RAW = true;
    };
    extraOptions = [
      "--network=host"
    ];
  };
}
