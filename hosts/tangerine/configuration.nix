{
  self,
  modulesPath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
    ./preservation.nix
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
    hashedPasswordFile = "/persistent/passwd"; # mkpasswd -m yescrypt "a4b32x4yb" > /persistent/passwd
    extraGroups = [
      "wheel"
    ];
  };

  networking.interfaces.enp1s0.ipv6.addresses = [
    {
      address = "2a01:4f9:c012:5531::1";
      prefixLength = 64;
    }
  ];

  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp1s0";
  };

  system.stateVersion = "26.05"; # Did you read the comment?
}
