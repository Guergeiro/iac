{ inputs, ... }:
let
  inherit (inputs)
    self
    agenix
    disko
    preservation
    ;

in
{
  flake.nixosModules."tangerine-configuration" =
    {
      pkgs,
      modulesPath,
      host,
      hostname,
      ...
    }:
    let
      inherit (host) username;
    in
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")

        agenix.nixosModules.default
        disko.nixosModules.disko
        preservation.nixosModules.default

        self.nixosModules."${hostname}-hardware-configuration"
        self.nixosModules."${hostname}-disk-config"
        self.nixosModules."${hostname}-preservation"

        self.nixosModules.nix
        self.nixosModules.docker
        self.nixosModules.server
        self.nixosModules.security
        self.nixosModules.ssh
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
    };
}
