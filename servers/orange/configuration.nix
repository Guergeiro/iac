{
  self,
  modulesPath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
    ./preservation.nix
    ./cloudflare-tunnel.nix
    ./homeassistant.nix
    "${self}/modules/nix.nix"
    "${self}/modules/docker.nix"
    "${self}/modules/server.nix"
    "${self}/modules/security.nix"
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

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

  users.users.${username} = {
    isNormalUser = true;
    # initialPassword = "12345"; # This is a placeholder password. Generate one after with mkpasswd
    hashedPasswordFile = "/persistent/passwd"; # mkpasswd -m yescrypt "password" > /persistent/passwd
    extraGroups = [
      "wheel"
    ];
  };

  system.stateVersion = "26.05"; # Did you read the comment?
}
