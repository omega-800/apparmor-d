{
  description = "apparmor.d profiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    aa-alias-manager = {
      url = "github:LordGrimmauld/aa-alias-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, aa-alias-manager, ... }@inputs:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "i686-linux" ];

      forEachSystem = definitions: nixpkgs.lib.genAttrs systems definitions;

      patchedNixpkgs = system:
        nixpkgs.legacyPackages.${system}.applyPatches {
          name = "nixpkgs-patched";
          src = inputs.nixpkgs;
          patches = [ ./apparmor-module.patch ];
        };

      patchedPkgs = system:
        import nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              inherit (self.packages.${system}) apparmor-d;
              inherit (aa-alias-manager.packages.${system}) aa-alias-manager;
            })
          ];
        };

      patchedNixosSystem = system:
        (import ((patchedNixpkgs system) + "/nixos/lib/eval-config.nix")) {
          inherit system;
          specialArgs = {
            inherit inputs system;
            pkgs = patchedPkgs system;
          };
          modules = [ ./test-host.nix self.nixosModules.apparmor-d ];
        };

      apparmorDModule = rec {
        apparmor-d = { ... }: { imports = [ ./apparmor-d-module.nix ]; };
        default = apparmor-d;
      };

      apparmorDPackage = system: rec {
        apparmor-d = (import nixpkgs { inherit system; }).callPackage
          ./apparmor-d-package.nix
          { inherit system; };
        default = apparmor-d;
      };

      testVmApp = system: rec {
        test-vm = {
          type = "app";
          program = "${
              self.nixosConfigurations.${system}.config.system.build.vm
            }/bin/run-nixos-vm";
        };
        default = test-vm;
      };
    in
    {
      nixosConfigurations = forEachSystem patchedNixosSystem;
      nixosModules = apparmorDModule;
      packages = forEachSystem apparmorDPackage;
      apps = forEachSystem testVmApp;
      formatter = forEachSystem
        (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
      #TODO: 
      # checks = { }; 
    };
}
