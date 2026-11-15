{ inputs, self, ... }:
let
  hostname = "macbook";
  host = builtins.fromJSON (builtins.readFile "${inputs.nix-secrets}/${hostname}/host.json");
in
{
  flake.darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit
        inputs
        hostname
        host
        ;
    };
    modules = [
      self.darwinModules."${hostname}-configuration"
    ];
  };
}
