# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "breno-laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.resolvconf.dnsExtensionMechanism = false;
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];

  # Enable networking
  networking.networkmanager = {
    enable = true;
    ethernet.macAddress = "permanent";
    wifi.macAddress = "random";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Lisbon";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT = "pt_PT.UTF-8";
    LC_MONETARY = "pt_PT.UTF-8";
    LC_NAME = "pt_PT.UTF-8";
    LC_NUMERIC = "pt_PT.UTF-8";
    LC_PAPER = "pt_PT.UTF-8";
    LC_TELEPHONE = "pt_PT.UTF-8";
    LC_TIME = "pt_PT.UTF-8";
  };

  services.xserver = {
    enable = true;
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs; [
        luaPackages.luarocks
        luaPackages.luadbi-mysql
      ];
    };
    desktopManager.runXdgAutostartIfNone = true;
    displayManager = {
      lightdm.enable = true;
      lightdm.greeters.gtk = {
        enable = true;
        theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
        };
        cursorTheme = {
          name = "Dracula-cursors";
          package = pkgs.dracula-theme;
        };
        iconTheme = {
          name = "Dracula";
          package = pkgs.dracula-icon-theme;
        };
      };
    };
    # Configure keymap in X11
    xkb = {
      layout = "us,us(intl)";
      variant = "";
    };
  };

  services.displayManager = {
    defaultSession = "none+awesome";
  };

  services.pulseaudio.enable = true;

  services.pipewire = {
    enable = false;
  #  pulse.enable = true;
  };

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 60;
    };
  };

  programs.dconf.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    description = "Breno Salles";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      stremio
      xclip
      signal-desktop
      thunderbird
      spotify
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings = {
      live-restore = true;
      ipv6 = true;
      fixed-cidr-v6 = "2001:818:dba0:5c00::/56";
    };
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
  };

  nix.gc.dates = "daily";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    awesome
    legcord
    google-lighthouse
    galculator

    tlp
    acpi
    blueman
    brightnessctl
    docker
    gimp3
    lightlocker

    reaction
    networkmanager
    networkmanagerapplet
    wireguard-tools
    wg-netmanager

    zip
    unzip

    pavucontrol
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.xfce4-battery-plugin
    xfce.xfce4-taskmanager
    xfce.xfce4-screenshooter
    xfce.xfce4-pulseaudio-plugin
    xfce.xfce4-power-manager
  ];

  environment.shellAliases = {
    # Create a new copy/paste command that allows too feed/read content directly to/from xclip
    copy="${pkgs.xclip}/bin/xclip -i -selection clipboard";
    paste="${pkgs.xclip}/bin/xclip -o -selection clipboard";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [
  #   51820 # WireGuard
  # ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall = {
    # if packets are still dropped, they will show up in dmesg
    logReversePathDrops = true;
    # wireguard trips rpfilter up
    extraCommands = ''
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN
      ip46tables -t mangle -I nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN
    '';
    extraStopCommands = ''
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --sport 51820 -j RETURN || true
      ip46tables -t mangle -D nixos-fw-rpfilter -p udp -m udp --dport 51820 -j RETURN || true
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
