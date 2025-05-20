{ self, pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

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
      settings = {
        mode.main.binding = {
          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-5 = "workspace 5";
          alt-6 = "workspace 6";
          alt-7 = "workspace 7";
          alt-8 = "workspace 8";
          alt-9 = "workspace 9";

          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";

          alt-shift-r = "reload-config";
          alt-f = "layout floating tiling";
          f11 = "macos-native-fullscreen";
        };
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
