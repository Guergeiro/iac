{
  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    let
      inherit (import ./_hooks.nix pkgs) hooksEnv;
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [ inputs'.git-format-staged.packages.default ];
        env = hooksEnv;
      };
    };
}
