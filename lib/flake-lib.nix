{ inputs }:
let
  inherit (inputs) nixpkgs self;
in
rec {
  systems = [
    # TODO: cross platform builds
    "x86_64-linux" # "i686-linux" "aarch64-linux"
  ];

  forEachSystem = definitions: nixpkgs.lib.genAttrs systems definitions;

  patchedNixpkgs =
    system:
    nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixpkgs-patched";
      src = nixpkgs;
      patches = [ ../modules/apparmor-module.patch ];
    };

  mkOverlays = system: [
    (final: prev: {
      inherit (self.packages.${system}) apparmor-d;
      inherit (inputs.aa-alias-manager.packages.${system}) aa-alias-manager;
    })
  ];

  patchedPkgs =
    system:
    import nixpkgs {
      inherit system;
      overlays = mkOverlays system;
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
        # {
        #   nixpkgs.config.allowUnsupportedSystem = true;
        #   nixpkgs.hostPlatform.system = system;
        #   nixpkgs.buildPlatform.system = "x86_64-linux";
        # }
      ];
    };

  mkApparmorDModule = rec {
    apparmor-d =
      { ... }:
      {
        imports = [
          ../modules/apparmor-d-module.nix
          inputs.aa-alias-manager.nixosModules.default
        ];
      };
    default = apparmor-d;
  };

  mkApparmorDPackage = system: rec {
    apparmor-d = nixpkgs.legacyPackages.${system}.callPackage ../packages/apparmor-d-package.nix { };
    default = apparmor-d;
  };

  mkLegacyPackages =
    system:
    import nixpkgs {
      inherit system;
      overlays = mkOverlays system;
      crossOverlays = mkOverlays system;
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
  mkChecks =
    system:
    let
      inherit (nixpkgs.legacyPackages.${system}) lib;
    in
    {
      pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks.nixpkgs-fmt.enable = true;
      };
    }
    // (lib.mapAttrs'
      (
        n: v:
        let
          name = lib.removeSuffix ".nix" n;
        in
        lib.nameValuePair name (
          (import ((patchedNixpkgs system) + "/nixos/lib") { }).runTest (
            {
              hostPkgs = patchedPkgs system;
              imports = [
                {
                  inherit name;
                  meta.maintainers = [
                    {
                      github = "omega-800";
                      githubId = 50942480;
                      name = "omega";
                    }
                  ];
                  nodes.test =
                    { ... }:
                    {
                      imports = [
                        ../hosts/test-host.nix
                        self.nixosModules.apparmor-d
                      ];
                      nixpkgs.overlays = mkOverlays system;
                    };
                }
              ];
            }
            // (import ../checks/${n})
          )
        )
      )
      (builtins.readDir ../checks));

  mkGithubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
    checks = {
      # TODO: support for more architectures
      x86_64-linux = self.checks.x86_64-linux // self.packages.x86_64-linux;
    };
  };
}
