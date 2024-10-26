{ inputs }:
let
  inherit (inputs) nixpkgs self;
in
rec {
  patchedNixpkgs =
    system:
    nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixpkgs-patched";
      src = inputs.nixpkgs;
      patches = [ ../modules/apparmor-module.patch ];
    };

  patchedPkgs =
    system:
    import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          inherit (self.packages.${system}) apparmor-d;
          inherit (inputs.aa-alias-manager.packages.${system}) aa-alias-manager;
        })
      ];
    };

  mkPatchedNixosSystem =
    system:
    (import ((patchedNixpkgs system) + "/nixos/lib/eval-config.nix")) {
      inherit system;
      specialArgs = {
        inherit inputs system;
        pkgs = patchedPkgs system;
      };
      modules = [
        ../hosts/test-host.nix
        self.nixosModules.apparmor-d
      ];
    };

  mkApparmorDModule = rec {
    apparmor-d =
      { ... }:
      {
        imports = [ ../modules/apparmor-d-module.nix ];
      };
    default = apparmor-d;
  };

  mkApparmorDPackage = system: rec {
    apparmor-d = nixpkgs.legacyPackages.${system}.callPackage ../packages/apparmor-d-package.nix { };
    default = apparmor-d;
  };

  mkTestVmApp = system: rec {
    test-vm = {
      type = "app";
      program = "${self.nixosConfigurations.${system}.config.system.build.vm}/bin/run-nixos-vm";
    };
    default = test-vm;
  };

  mkDevShell = system: rec {
    apparmor-d = nixpkgs.legacyPackages.${system}.mkShell {
      inherit (self.checks.${system}.pre-commit-check) shellHook;
      buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
      packages = with nixpkgs.legacyPackages.${system}; [
        nil
        nixfmt-rfc-style
      ];
    };
    default = apparmor-d;
  };

  mkFormatter = system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

  # TODO:check for apparmor-d profiles validity as well as 
  # compatibility between different versions 
  mkChecks = system: {
    pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks.nixpkgs-fmt.enable = true;
    };
  };
}
