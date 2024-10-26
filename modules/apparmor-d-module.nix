{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    filterAttrs
    mapAttrsToList
    genAttrs
    mkForce
    mkDefault
    getExe
    attrNames
    concatMapStringsSep
    ;
  inherit (builtins) readDir hasAttr mapAttrs;
  cfg = config.security.apparmor-d;
  allProfileNames = mapAttrsToList (n: v: n) (
    filterAttrs (n: v: v == "regular") (readDir "${pkgs.apparmor-d}/etc/apparmor.d")
  );
  profileStatus = types.enum [
    "disable"
    "complain"
    "enforce"
  ];
  aliasDir = "/run/aliases.d";
in
{
  options.security.apparmor-d = {
    enable = mkEnableOption "Enables apparmor.d support";

    statusAll = mkOption {
      type = profileStatus;
      default = "disable";
      description = ''
        Can be set to "enforce" or "complain" to enable all profiles and set their flags to enforce or complain respectively
      '';
    };

    profiles = mkOption {
      type = types.attrsOf profileStatus;
      default = { };
      description = "Set of apparmor profiles to include from apparmor.d";
    };

    enableAliases = mkOption {
      type = types.bool;
      default = true;
      description = "Enables usage of aa-alias-manager for profile path alias generation";
    };
  };

  config = mkIf cfg.enable {
    security.apparmor = {
      includes = mkIf cfg.enableAliases {
        "tunables/alias.d/store" = ''
          include if exists "${aliasDir}"
        '';
      };

      packages = [ pkgs.apparmor-d ];
      policies =
        if (cfg.statusAll != "disable") then
          (genAttrs allProfileNames (name: {
            state = mkDefault (if (hasAttr name cfg.profiles) then cfg.profiles.${name} else cfg.statusAll);
            path = "${pkgs.apparmor-d}/etc/apparmor.d/${name}";
          }))
        else
          (mapAttrs (name: state: {
            inherit state;
            path = "${pkgs.apparmor-d}/etc/apparmor.d/${name}";
          }) cfg.profiles);
    };

    environment = {
      systemPackages = [ pkgs.apparmor-d ];
      etc."apparmor/parser.conf".text = ''
        Optimize=compress-fast
      '';
    };

    systemd.services.aa-alias-setup = mkIf cfg.enableAliases {
      wantedBy = [ "apparmor.service" ];
      path = [
        config.nix.package
      ]; # respect the users choice to use alternative nix implementations

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${getExe pkgs.aa-alias-manager} -o ${aliasDir} -p ${
          pkgs.writeText "aa-alias-patterns.json"
            # json
            ''
              [
                {
                  "name": "bin",
                  "target": "/bin",
                  "pattern": [
                    "bin",
                    "libexec",
                    "sbin",
                    "usr/bin",
                    "usr/sbin"
                  ],
                  "individual": true,
                  "only_exe": true,
                  "disallowed_strings": [ "!" ],
                  "only_include": [ ${concatMapStringsSep (n: ''"${n}"'') ", " (attrNames cfg.profiles)} ]
                }
              ]
            ''
        }";
      };
    };

    # provide alternative boot entry in case apparmor rules break things
    specialisation.disabledApparmorD.configuration = {
      security.apparmor-d.enable = mkForce false;
      system.nixos.tags = [ "without-apparmor.d" ];
    };
  };
}
