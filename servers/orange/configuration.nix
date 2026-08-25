{
  modulesPath,
  pkgs,
  hostname,
  username,
  publicSshKey,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  networking.hostName = hostname;
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    neovim
    docker
    coreutils
  ];

  environment.variables = {
    EDITOR = "${pkgs.neovim}/bin/nvim";
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      options = "--delete-older-than 5d";
      dates = "daily";
    };
    # Automatically free whenever less than 1GB remaining
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
    '';
  };
  users.users.root = {
    openssh.authorizedKeys.keys = [
      publicSshKey
    ];
  };
  users.users.${username} = {
    isNormalUser = true;
    # initialPassword = "12345"; # This is a placeholder password. Generate one after with mkpasswd
    hashedPasswordFile = "/persistent/passwd"; # mkpasswd -m yescrypt "password" > /persistent/passwd
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      publicSshKey
    ];
  };
  users.mutableUsers = false;

  networking.firewall.enable = true;

  virtualisation.containers.enable = true;
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
  virtualisation.oci-containers.backend = "docker";

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
    };
  };

  system.stateVersion = "26.05"; # Did you read the comment?
}
