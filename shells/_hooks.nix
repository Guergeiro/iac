pkgs:
let
  hookScripts = {
    pre-commit = pkgs.writeShellScript "pre-commit" ''
      format_staged_nix_files() {
        git-format-staged -f '${pkgs.nixfmt}/bin/nixfmt --filename {}' '*.nix'
      }

      format_staged_tf_files() {
        git-format-staged -f '${pkgs.opentofu}/bin/tofu fmt {}' '*.tf'
      }

      format_staged_nix_files
      format_staged_tf_files
    '';
    post-commit = pkgs.writeShellScript "post-commit" ''
      exec ${pkgs.git}/bin/git update-index -g
    '';
  };
in
{
  inherit hookScripts;
  hooksEnv = {
    GIT_CONFIG_COUNT = "1";
    GIT_CONFIG_KEY_0 = "core.hooksPath";
    GIT_CONFIG_VALUE_0 = pkgs.linkFarm "git-hooks" (
      pkgs.lib.mapAttrsToList (name: path: {
        inherit name path;
      }) hookScripts
    );
  };
}
