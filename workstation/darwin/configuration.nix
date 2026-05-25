{
  self,
  pkgs,
  username,
  ...
}:
{

  environment.systemPackages = with pkgs; [
    vscode
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    brews = [ ];
    casks = [
      "karabiner-elements"
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
      "com.apple.swipescrolldirection" = true;
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
    universalaccess.reduceMotion = true;
    universalaccess.reduceTransparency = true;
    iCal."first day of week" = "Monday";
  };

  system.keyboard = {
    enableKeyMapping = false;
    # nonUS.remapTilde = true;
    # swapLeftCtrlAndFn = true;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  networking = {
    knownNetworkServices = [
      "Realtek LAN"
      "Dell Universal Dock D6000"
      "USB 10/100/1000 LAN"
      "Thunderbolt Bridge"
      "Wi-Fi"
      "iPhone USB"
    ];
    dns = [
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };

  nix.gc.interval = {
    Hour = 0;
    Minute = 0;
  };

  programs.bash.enable = true;

  # Don't use the default profile because of path_helper. This might get overwritten during system updates
  # https://github.com/nix-darwin/nix-darwin/issues/391#issuecomment-2690508643
  environment.etc.profile = {
    text = ''
      if [ -d /private/etc/paths.d ]; then
        for f in /private/etc/paths.d/*; do
          [ -f "$f" ] || continue  # Skip and suppress error
          while IFS="" read -r l || [ -n "$l" ]; do
            PATH="$PATH:$l"
            done <"$f"
          done
        export PATH
      fi

      if [ -d /private/etc/manpaths.d ]; then
        for f in /private/etc/manpaths.d/*; do
          [ -f "$f" ] || continue  # Skip and suppress error
          while IFS="" read -r l || [ -n "$l" ]; do
            MANPATH="$MANPATH:$l"
            done <"$f"
          done
        export MANPATH
      fi

      if [ "$BASH-no" != "no" ]; then
        [ -r /etc/bashrc ] && . /etc/bashrc
      fi
    '';
    target = "profile";
  };

  users.knownUsers = [ "${username}" ];
  users.users.${username}.uid = 501;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
