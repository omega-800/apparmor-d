{ stdenv
, buildGoModule
, fetchFromGitHub
, lib
, nix-update-script
, git
,
}:
buildGoModule {
  pname = "apparmor-d";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "roddhjav";
    repo = "apparmor.d";
    rev = "25049292ebd9f02dd0bfc4925dcacb2144a94b62";
    hash = "sha256-z0Jo7hK/Gu/DMuJ/WbYZK3aq5+s9vCLxxCR++bpkC0Y=";
  };

  vendorHash = null;

  #doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  nativeBuildInputs = [ git ];

  patches = [ ./apparmor-d-package.patch ];

  postInstall = ''
    mkdir $out/etc

    export DISTRIBUTION=nixos 
    export PKGNAME=apparmor-d
    $out/bin/prebuild 

    mv .build/apparmor.d $out/etc
    rm $out/bin/prebuild
  '';

  subPackages = [
    "cmd/prebuild"
    "cmd/aa-log"
  ];

  meta = {
    homepage = "https://apparmor.pujol.io";
    description = "Collection of apparmor profiles";
    licenses = with lib.licenses; [
      gpl2
      gpl2Only
    ];
    mainProgram = "aa-log";
    platforms = lib.platforms.linux;
    maintainers = [
      {
        github = "omega-800";
        githubId = 50942480;
        name = "omega";
      }
    ];
  };
}
