{
  description = "apparmor.d profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aa-alias-manager = {
      url = "github:LordGrimmauld/aa-alias-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      inherit (import ./lib/flake-lib.nix { inherit inputs; })
        forEachSystem
        mkTestVmApp
        mkFormatter
        mkApparmorDModule
        mkApparmorDPackage
        mkDevShell
        mkChecks
        mkPatchedNixosSystem
        mkGithubActions
        mkLegacyPackages
        ;
    in
    {
      checks = forEachSystem mkChecks;
      nixosConfigurations = forEachSystem mkPatchedNixosSystem;
      nixosModules = mkApparmorDModule;
      packages = forEachSystem mkApparmorDPackage;
      legacyPackages = forEachSystem mkLegacyPackages;
      apps = forEachSystem mkTestVmApp;
      devShells = forEachSystem mkDevShell;
      formatter = forEachSystem mkFormatter;
      githubActions = mkGithubActions;
    };
}
