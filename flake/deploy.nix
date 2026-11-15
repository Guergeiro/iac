{ lib, ... }:
{
  options.flake.deploy.nodes = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Deploy-rs deployment nodes.";
  };
}
