{ inputs, ... }:
let
  inherit (inputs) nix-secrets;

  wireguardIpv4Address = "10.100.0";
  wireguardIpv6Address = "fdba:af61:93e3";

  wgInterface = "wg0";
in
{
  flake.nixosModules."orange-networking" =
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
          "${wireguardIpv4Address}.2/24"
          "${wireguardIpv6Address}::2/64"
        ];
        privateKeyFile = config.age.secrets.wg_key.path;

        peers = [
          {
            publicKey = builtins.readFile "${nix-secrets}/tangerine/wg_key.pub";
            endpoint = "tangerine.${envVars.BASE_DOMAIN}:51820";
            persistentKeepalive = 25;
            allowedIPs = [
              "${wireguardIpv4Address}.2/32"
              "${wireguardIpv6Address}::2/128"
              # Uncomment the following lines to route all traffic through the VPN
              # "0.0.0.0/0"
              # "::/0"
            ];
          }
        ];
      };
    };
}
