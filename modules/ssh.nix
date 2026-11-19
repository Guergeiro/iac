{ inputs, ... }:
let
  inherit (inputs) nix-secrets;

  userPublicSshKey = builtins.readFile "${nix-secrets}/id_ed25519.pub";

  persistencePath = "/persistent/etc/ssh";

  serverPrivateKeys = {
    id_ed25519 = "ssh_host_ed25519_key";
    rsa = "ssh_host_rsa_key";
  };

in
{
  flake.nixosModules.ssh =
    {
      lib,
      hostname,
      host,
      ...
    }:
    let
      inherit (host) username;
      serverPublicKeys = lib.mapAttrs (name: value: "${value}.pub") serverPrivateKeys;
    in
    {
      # privateKeys should be identityPaths
      age.identityPaths = map (keyName: "${persistencePath}/${keyName}") (
        lib.attrValues serverPrivateKeys
      );

      age.secrets = lib.mkMerge [
        (lib.genAttrs (lib.attrValues serverPrivateKeys) (name: {
          file = "${nix-secrets}/${hostname}/${name}.age";
          path = "${persistencePath}/${name}";
          symlink = false;
        }))
        {
          "${hostname}/env".file = "${nix-secrets}/${hostname}/env.age";
        }
      ];

      environment.etc = lib.mapAttrs' (name: filename: {
        name = "ssh/${filename}";
        value = {
          source = "${nix-secrets}/${hostname}/${filename}";
        };
      }) serverPublicKeys;

      services.openssh = {
        enable = true;
        generateHostKeys = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };

        hostKeys = [
          {
            bits = 4096;
            path = "/etc/ssh/${serverPrivateKeys.rsa}";
            type = "rsa";
          }
          {
            path = "/etc/ssh/${serverPrivateKeys.id_ed25519}";
            type = "ed25519";
          }
        ];
      };

      users.users.root.openssh.authorizedKeys.keys = [
        userPublicSshKey
      ];
      users.users.${username}.openssh.authorizedKeys.keys = [
        userPublicSshKey
      ];
    };
}
