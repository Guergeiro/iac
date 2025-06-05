{ self, pkgs, username, ... }:
{

  environment.systemPackages = with pkgs; [
    aerospace
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    casks = [
      "docker"
    ];
  };

  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  system.primaryUser = username;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.defaults = {
    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = true;
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      "com.apple.keyboard.fnState" = true;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.trackpadCornerClickBehavior" = 1;
    };
    trackpad = {
      TrackpadRightClick = true;
    };
    hitoolbox.AppleFnUsageType = "Do Nothing";
    controlcenter.BatteryShowPercentage = true;
    dock = {
      autohide = true;
      autohide-delay = 0.1;
      launchanim = false;
      mineffect = "scale";
      tilesize = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 4;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowPathbar = true;
      FXPreferredViewStyle = "clmv";
      QuitMenuItem = true;
    };
    loginwindow.GuestEnabled = false;
    menuExtraClock.Show24Hour = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    nonUS.remapTilde = true;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.gc.interval = {
    Hour = 24;
    Minute = 0;
  };

  programs = {
    zsh = {
      enable = true;
      shellInit = "${pkgs.bashInteractive}/bin/bash && exit";
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  services = {
    aerospace = {
      enable = true;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
