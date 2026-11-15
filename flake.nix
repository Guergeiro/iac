{
  description = "IaC flake";

  inputs = {
    self.submodules = true;

    # Platform-specific nixpkgs channels
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin?ref=nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    import-tree.url = "github:denful/import-tree";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    nix-secrets = {
      url = "./nix-secrets";
      flake = false;
    };

    home-manager.url = "github:nix-community/home-manager?ref=release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Need to use git+ssh to work around: https://github.com/NixOS/nix/issues/13571
    dotfiles.url = "git+ssh://git@github.com/guergeiro/dotfiles.git";
    dotfiles.inputs.nixpkgs.follows = "nixpkgs";
    dotfiles.inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
    dotfiles.inputs.home-manager.follows = "home-manager";
    dotfiles.inputs.nix-secrets.follows = "nix-secrets";
    dotfiles.inputs.agenix.follows = "agenix";
    dotfiles.inputs.systems.follows = "systems";
    dotfiles.inputs.import-tree.follows = "import-tree";
    dotfiles.inputs.flake-parts.follows = "flake-parts";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";

    git-format-staged.url = "github:hallettj/git-format-staged";
    git-format-staged.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        (inputs.import-tree [
          ./flake
          ./hosts
          ./modules
          ./shells
        ])
      ];
    };
}
