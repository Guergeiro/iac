{ inputs, self, ... }:
let
  hostname = "mango";
  host = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/${hostname}/host.json");
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
