{
  description = "apparmor.d profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aa-alias-manager = {
      url = "github:LordGrimmauld/aa-alias-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (import ./lib/flake-lib.nix { inherit inputs; })
        mkTestVmApp
        mkFormatter
        mkApparmorDModule
        mkApparmorDPackage
        mkDevShell
        mkChecks
        mkPatchedNixosSystem
        ;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "i686-linux"
      ];
      forEachSystem = definitions: nixpkgs.lib.genAttrs systems definitions;
    in
    {
      nixosConfigurations = forEachSystem mkPatchedNixosSystem;
      nixosModules = mkApparmorDModule;
      packages = forEachSystem mkApparmorDPackage;
      apps = forEachSystem mkTestVmApp;
      devShells = forEachSystem mkDevShell;
      formatter = forEachSystem mkFormatter;
      checks = forEachSystem mkChecks;
    };
}
