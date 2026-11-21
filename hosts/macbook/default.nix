{ inputs, self, ... }:
let
  hostname = "macbook";
  host = import "${inputs.nix-secrets}/${hostname}/host.nix";
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
