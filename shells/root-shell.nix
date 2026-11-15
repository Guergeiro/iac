{
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    let
      inherit (import ./_hooks.nix pkgs) hooksEnv;

      anywhereScript = pkgs.writeShellScriptBin "nix-anywhere" ''
        ${pkgs.nix}/bin/nix run github:nix-community/nixos-anywhere -- --flake $1 --target-host nixos@$2
      '';
    in
    {
      devShells.root-shell = pkgs.mkShellNoCC {
        inputsFrom = [ self'.devShells.default ];
        packages = [
          pkgs.nixfmt
          pkgs.nixd
          pkgs.git-crypt
          anywhereScript
          inputs'.deploy-rs.packages.default
          inputs'.agenix.packages.default
        ];
        env = hooksEnv;
      };
    };
}
