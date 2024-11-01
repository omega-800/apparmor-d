{ pkgs
, lib
, config
, ...
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
    attrNames
    ;
  inherit (builtins) readDir mapAttrs filter;
  cfg = config.security.apparmor-d;
  profileStatus = types.enum [
    "disable"
    "complain"
    "enforce"
  ];
  allProfileNames = mapAttrsToList (n: v: n) (
    filterAttrs (n: v: v == "regular") (readDir "${pkgs.apparmor-d}/etc/apparmor.d")
  );
  enabledProfiles = filter (p: (cfg.profiles.${p} or cfg.status) != "disable") allProfileNames;
in
{
  options.security.apparmor-d = {
    enable = mkEnableOption "Enables apparmor.d support";

    status = mkOption {
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
      packages = [ pkgs.apparmor-d ];
      policies =
        if (cfg.status != "disable") then
          (genAttrs enabledProfiles (name: {
            state = mkDefault (cfg.profiles.${name} or cfg.status);
            path = "${pkgs.apparmor-d}/etc/apparmor.d/${name}";
          }))
        else
          (mapAttrs
            (name: state: {
              inherit state;
              path = "${pkgs.apparmor-d}/etc/apparmor.d/${name}";
            })
            (filterAttrs (n: v: v != "disable") cfg.profiles));
      aa-alias-manager = mkIf cfg.enableAliases {
        # aliases aren't loaded if profile path is glob, see 
        # https://gitlab.com/apparmor/apparmor/-/issues/455
        enable = lib.mkForce false;
        patterns = [
          {
            name = "bin";
            target = "/bin";
            store_suffixes = [
              "bin"
              "libexec"
              "sbin"
              "usr/bin"
              "usr/sbin"
            ];
            individual = true;
            only_exe = true;
            only_include = enabledProfiles;
          }
          {
            name = "lib";
            target = "/lib";
            store_suffixes = [
              "lib"
              "libexec"
              "lib32"
              "lib64"
              "usr/lib64"
              "usr/lib32"
              "usr/libexec"
            ];
            individual = true;
            only_include = enabledProfiles;
          }
        ];
      };
    };

    environment = {
      systemPackages = [ pkgs.apparmor-d ];
      etc."apparmor/parser.conf".text = ''
        Optimize=compress-fast
      '';
    };

    # provide alternative boot entry in case apparmor rules break things
    specialisation.disabledApparmorD.configuration = {
      security.apparmor-d.enable = mkForce false;
      system.nixos.tags = [ "without-apparmor.d" ];
    };
  };
}
