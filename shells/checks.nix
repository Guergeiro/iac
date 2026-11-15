{ inputs, self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = (inputs.deploy-rs.lib.${system}.deployChecks self.deploy) // {
        nix-fmt =
          pkgs.runCommand "check-nix-fmt"
            {
              buildInputs = [ pkgs.nixfmt ];
            }
            ''
              ${pkgs.nixfmt}/bin/nixfmt --check .
              touch $out
            '';

        tofu-fmt =
          pkgs.runCommand "check-tofu-fmt"
            {
              buildInputs = [
                pkgs.opentofu
                pkgs.coreutils
              ];
            }
            ''
              ${pkgs.opentofu}/bin/tofu fmt -check -recursive ${../infra}
              ${pkgs.coreutils}/bin/touch $out
            '';
      };
    };
}
