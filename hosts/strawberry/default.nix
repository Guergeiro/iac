{ inputs, self, ... }:
let
  hostname = "strawberry";
  host = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/${hostname}/host.json");
in
{
  flake = {
    nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          hostname
          host
          ;
      };
      modules = [
        self.nixosModules."${hostname}-configuration"
      ];
    };
    deploy.nodes.${hostname} = {
      hostname = "${hostname}.${host.environment.BASE_DOMAIN}"; # Initially we need the ip address
      profiles.system = {
        sshUser = "root";
        path = inputs.deploy-rs.lib.${host.system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };
}
