{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      inherit (import ./_hooks.nix pkgs) hooksEnv;
    in
    {
      devShells.tf-shell = pkgs.mkShellNoCC {
        inputsFrom = [ self'.devShells.default ];

        packages = [
          pkgs.opentofu
          # Create a wrapper executable named "terraform" that proxies to opentofu
          (pkgs.writeShellScriptBin "terraform" ''
            exec ${pkgs.opentofu}/bin/tofu "$@"
          '')

          (pkgs.writeShellScriptBin "tf-init" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 init -backend-config=../../env-backend/$1.tfbackend -var-file=../../env-vars/$1.tfvars
          '')
          (pkgs.writeShellScriptBin "tf-validate" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 validate -var-file=../../env-vars/$1.tfvars
          '')
          (pkgs.writeShellScriptBin "tf-plan" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 plan -var-file=../../env-vars/$1.tfvars -out=tfplan
          '')
          (pkgs.writeShellScriptBin "tf-apply" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 apply tfplan
          '')
          (pkgs.writeShellScriptBin "tf-destroy-plan" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 plan -destroy -var-file=../../env-vars/$1.tfvars -out=tfdestroyplan
          '')
          (pkgs.writeShellScriptBin "tf-destroy-apply" ''
            exec ${pkgs.opentofu}/bin/tofu -chdir=hosts/$1 apply tfdestroyplan
          '')
        ];

        env = hooksEnv;
      };
    };
}
