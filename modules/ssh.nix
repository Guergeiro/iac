{
  lib,
  hostname,
  nix-secrets,
  ...
}:
let
  persistencePath = "/persistent/etc/ssh";

  privateKeys = {
    id_ed25519 = "ssh_host_ed25519_key";
    rsa = "ssh_host_rsa_key";
  };

  publicKeys = lib.mapAttrs (name: value: "${value}.pub") privateKeys;
in
{

  # privateKeys should be identityPaths
  age.identityPaths = map (keyName: "${persistencePath}/${keyName}") (lib.attrValues privateKeys);

  age.secrets = lib.mkMerge [
    (lib.genAttrs (lib.attrValues privateKeys) (name: {
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
  }) publicKeys;

  services.openssh = {
    enable = true;
    generateHostKeys = false;
    hostKeys = [
      {
        bits = 4096;
        path = "/etc/ssh/${privateKeys.rsa}";
        type = "rsa";
      }
      {
        path = "/etc/ssh/${privateKeys.id_ed25519}";
        type = "ed25519";
      }
    ];
  };
}
