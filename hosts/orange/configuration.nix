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
  flake.nixosModules."orange-configuration" =
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
        (modulesPath + "/installer/scan/not-detected.nix")
        (modulesPath + "/profiles/qemu-guest.nix")

        agenix.nixosModules.default
        disko.nixosModules.disko
        preservation.nixosModules.default

        self.nixosModules."${hostname}-hardware-configuration"
        self.nixosModules."${hostname}-disk-config"
        self.nixosModules."${hostname}-preservation"
        self.nixosModules."${hostname}-networking"

        self.nixosModules."${hostname}-cloudflare-tunnel"
        self.nixosModules."${hostname}-homeassistant"

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
        hashedPasswordFile = "/persistent/passwd"; # mkpasswd -m yescrypt "password" > /persistent/passwd
        extraGroups = [
          "wheel"
        ];
      };

      system.stateVersion = "26.05"; # Did you read the comment?
    };
}
