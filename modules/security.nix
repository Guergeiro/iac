{ ... }:
let
  config = {
    # https://emudhra.we-have-a-problem.com/
    security.pki.caCertificateBlacklist = [
      # "Comodo AAA Services root"
      # "emSign ECC Root CA - G3"
    ];
  };
in
{
  flake.nixosModules.security = { ... }: config;
  flake.darwinModules.security = { ... }: config;
}
