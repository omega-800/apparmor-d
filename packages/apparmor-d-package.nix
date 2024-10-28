{
  stdenv,
  fetchFromGitHub,
  go,
  lib,
  nix-update-script,
}:
stdenv.mkDerivation {
  pname = "apparmor-d";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "roddhjav";
    repo = "apparmor.d";
    rev = "25049292ebd9f02dd0bfc4925dcacb2144a94b62";
    hash = "sha256-z0Jo7hK/Gu/DMuJ/WbYZK3aq5+s9vCLxxCR++bpkC0Y=";
  };

  # doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  passthru.updateScript = nix-update-script { };

  nativeBuildInputs = [ go ];

  patches = [ ./apparmor-d-package.patch ];

  buildPhase = ''
    HOME=$(pwd) make
  '';

  installPhase = ''
    DISTRIBUTION=nixos DESTDIR=$out PKGNAME=apparmor-d make install
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
    maintainers = [
      {
        github = "omega-800";
        githubId = 50942480;
        name = "omega";
      }
    ];
    mainProgram = "aa-log";
    platforms = lib.platforms.linux;
  };
}
