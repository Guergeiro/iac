{ inputs, ... }:
let
  inherit (inputs) nix-secrets;

  wireguardIpv4Address = "10.100.0";
  wireguardIpv6Address = "fdba:af61:93e3";

  networkInterface = "enp1s0";
  wgInterface = "wg0";

  allowedPeers = [
    "orange"
  ];

  allowedPeersKeys = map (peer: builtins.readFile "${nix-secrets}/${peer}/wg_key.pub") allowedPeers;
in
{
  flake.nixosModules."tangerine-networking" =
    {
      pkgs,
      lib,
      hostname,
      config,
      ...
    }:
    {
      age.secrets = lib.genAttrs [ "wg_key" ] (name: {
        file = "${nix-secrets}/${hostname}/${name}.age";
      });

      networking.interfaces.${networkInterface}.ipv6.addresses = [
        {
          address = "2a01:4f9:c012:5531::1";
          prefixLength = 64;
        }
      ];

      networking.defaultGateway6 = {
        address = "fe80::1";
        interface = networkInterface;
      };

      # enable NAT
      networking.nat.enable = true;
      networking.nat.enableIPv6 = true;
      networking.nat.externalInterface = networkInterface;
      networking.nat.internalInterfaces = [ wgInterface ];
      networking.firewall = {
        allowedUDPPorts = [ 51820 ];
      };

      networking.wg-quick.interfaces.${wgInterface} = {
        address = [
          "${wireguardIpv4Address}.1/24"
          "${wireguardIpv6Address}::1/64"
        ];

        listenPort = 51820;

        postUp = ''
          ${pkgs.iptables}/bin/iptables -A FORWARD -i ${wgInterface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${wireguardIpv4Address}.0/24 -o ${networkInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${wgInterface} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${wireguardIpv6Address}::/64 -o ${networkInterface} -j MASQUERADE
        '';
        # Undo the above
        postDown = ''
          ${pkgs.iptables}/bin/iptables -D FORWARD -i ${wgInterface} -j ACCEPT
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${wireguardIpv4Address}.0/24 -o ${networkInterface} -j MASQUERADE
          ${pkgs.iptables}/bin/ip6tables -D FORWARD -i ${wgInterface} -j ACCEPT
          ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s ${wireguardIpv6Address}::/64 -o ${networkInterface} -j MASQUERADE
        '';

        # Path to the private key file.
        #
        # Note: The private key can also be included inline via the privateKey option,
        # but this makes the private key world-readable; thus, using privateKeyFile is
        # recommended.
        privateKeyFile = config.age.secrets.wg_key.path;

        peers = lib.imap1 (i: peer: {
          publicKey = peer;
          allowedIPs = [
            "${wireguardIpv4Address}.${toString (i + 1)}/32"
            "${wireguardIpv6Address}::${toString (i + 1)}/128"
          ];
        }) allowedPeersKeys;
      };
    };
}
