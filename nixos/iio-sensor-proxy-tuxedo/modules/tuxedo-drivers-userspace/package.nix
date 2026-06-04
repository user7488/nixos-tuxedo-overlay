{
  lib,
  stdenv,
  fetchFromGitLab,
  bash,
  gitUpdater,
  udevCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tuxedo-drivers-userspace";
  version = "4.20.1";

  src = fetchFromGitLab {
    group = "tuxedocomputers";
    owner = "development/packages";
    repo = "tuxedo-drivers";
    rev = "v${finalAttrs.version}";
    hash = "sha256-t+Y1qYFJ9EeYtMFtBIsHzG1J4IVunpZHevYsEZNHGH0=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    # Fix paths in udev rules
    if [ -d "$out/lib/udev/rules.d" ]; then
      substituteInPlace $out/lib/udev/rules.d/* \
        --replace-quiet "/bin/bash" "${lib.getExe bash}" \
        --replace-quiet "/bin/sh" "${lib.getExe bash}"
    fi

    runHook postInstall
  '';

  nativeBuildInputs = [
    udevCheckHook
  ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = {
    description = "Udev rules and userspace utils for TUXEDO Computers laptops";
    homepage = "https://gitlab.com/tuxedocomputers/development/packages/tuxedo-drivers";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [
      aprl
      blanky0230
      keksgesicht
      xaverdh
      XBagon
      wetisobe
    ];
    platforms = lib.platforms.linux;
  };
})
