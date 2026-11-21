{ inputs, ... }:
let
  inherit (inputs) nix-secrets;

  wireguardIpv4Address = "10.100.0";
  wireguardIpv6Address = "fdba:af61:93e3";

  wgInterface = "wg0";
in
{
  flake.nixosModules."mango-networking" =
    {
      lib,
      hostname,
      config,
      host,
      ...
    }:
    let
      envVars = host.environment or { };
    in
    {
      age.secrets = lib.genAttrs [ "wg_key" ] (name: {
        file = "${nix-secrets}/${hostname}/${name}.age";
      });

      networking.wg-quick.interfaces.${wgInterface} = {
        address = [
          "${wireguardIpv4Address}.3/24"
          "${wireguardIpv6Address}::3/64"
        ];
        privateKeyFile = config.age.secrets.wg_key.path;

        peers = [
          {
            publicKey = builtins.readFile "${nix-secrets}/tangerine/wg_key.pub";
            endpoint = "${envVars.TANGERINE_DOMAIN}:51820";
            allowedIPs = [
              "${wireguardIpv4Address}.0/24"
              "${wireguardIpv6Address}::/64"
              # Uncomment the following lines to route all traffic through the VPN
              # "0.0.0.0/0"
              # "::/0"
            ];
          }
        ];
      };
    };
}
