{ inputs, self, ... }:
let
  hostname = "mango";
  host = import "${inputs.nix-secrets}/${hostname}/host.nix";
in
{
  flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
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
}
