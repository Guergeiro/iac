{ inputs, ... }:
let
  vars = [
    "cf_api_token"
    "cf_api_token_page_rules"
    "hetzner_api_token"
  ];

  secrets = [
    "access_key_id"
    "secret_access_key"
  ];
in
{

  imports = [
    inputs.agenix-shell.flakeModules.default
  ];

  agenix-shell = {
    secrets = (
      builtins.listToAttrs (
        map (var: {
          name = var;
          value = {
            file = "${inputs.nix-secrets}/infra/${var}.age";
            name = "TF_VAR_${var}";
          };
        }) vars
      )
      // (builtins.listToAttrs (
        map (secret: {
          name = secret;
          value = {
            file = "${inputs.nix-secrets}/infra/${secret}.age";
            name = "AWS_${inputs.nixpkgs.lib.toUpper secret}";
          };
        }) secrets
      ))
    );
  };

  perSystem =
    {
      pkgs,
      self',
      config,
      lib,
      ...
    }:
    let
      inherit (import ./_hooks.nix pkgs) hooksEnv;
    in
    {

      devShells.tf-shell = pkgs.mkShellNoCC {
        inputsFrom = [ self'.devShells.default ];

        shellHook = ''
          source ${lib.getExe config.agenix-shell.installationScript}
        '';

        packages = [
          pkgs.openssh
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

        env = hooksEnv // {
          TF_VAR_secrets_location = "${inputs.nix-secrets}";
        };
      };
    };
}
