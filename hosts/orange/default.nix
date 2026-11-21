{ inputs, self, ... }:
let
  hostname = "orange";
  host = import "${inputs.nix-secrets}/${hostname}/host.nix";
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
      hostname = "10.100.0.2"; # Initially we need the ip address
      profiles.system = {
        sshUser = "root";
        path = inputs.deploy-rs.lib.${host.system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };
}
