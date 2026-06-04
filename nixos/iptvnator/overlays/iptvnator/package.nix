{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm,
  electron,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  pkg-config,
  better-sqlite3 ? null,
}:

let
  pname = "iptvnator";
  version = "0.19.0";

  src = fetchFromGitHub {
    owner = "4gray";
    repo = "iptvnator";
    rev = "v${version}";
    hash = "sha256-2Zp//r0gh4vU/P+8UNU5oprq9BfAhPx9KfvbcIJ9+Sc=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  pnpmDeps = pnpm.fetchDeps {
    inherit pname version src;
    fetcherVersion = 3;
    hash = "sha256-TBpDyi3Nkw3ow3LBmoOv4/MIe6+fC4WIJs1o0EImgMs=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm.configHook
    makeWrapper
    copyDesktopItems
    python3
    pkg-config
  ];

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    # Point node-gyp (for better-sqlite3 native addon) at the right Electron headers
    npm_config_nodedir = electron.headers;
    # Nx crashes trying to open a PTY in the sandbox
    NX_DAEMON = "false";
    NX_NON_INTERACTIVE = "true";
    NX_TASKS_RUNNER_DYNAMIC_OUTPUT = "false";
    CI = "true";
  };

  postPatch = ''
    # Remove the postinstall script that runs electron-builder install-app-deps
    # (it tries to download Electron binaries)
    substituteInPlace package.json \
      --replace-quiet '"postinstall": "electron-builder install-app-deps",' ""

    # Patch out fix-path — it spawns a login shell to read $PATH, which is
    # unnecessary on NixOS (PATH is already set correctly by the wrapper)
    substituteInPlace apps/electron-backend/src/main.ts \
      --replace-quiet "import fixPath from 'fix-path';" "" \
      --replace-quiet "fixPath();" ""

    # Disable font inlining — no network access in the Nix sandbox
    ${nodejs}/bin/node -e "
      const fs = require('fs');
      const p = 'apps/web/project.json';
      const d = JSON.parse(fs.readFileSync(p, 'utf8'));
      const prod = d.targets.build.configurations.production;
      prod.optimization = { scripts: true, styles: true, fonts: { inline: false } };
      fs.writeFileSync(p, JSON.stringify(d, null, 2) + '\n');
    "
  '';

  buildPhase = ''
    runHook preBuild

    # Build the Angular frontend
    pnpm nx build web --configuration=production --skip-nx-cache --output-style=stream

    # Build the remote control web UI
    pnpm nx build remote-control-web --configuration=production --skip-nx-cache --output-style=stream

    # Build the worker scripts
    pnpm nx run electron-backend:build-worker --skip-nx-cache --output-style=stream

    # Build the Electron main process
    pnpm nx build electron-backend --configuration=production --skip-nx-cache --output-style=stream

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Create the app directory structure matching what electron-builder.json expects
    mkdir -p "$out/lib/iptvnator/resources/app"

    # Copy compiled Electron backend (main process)
    cp -r dist/apps/electron-backend "$out/lib/iptvnator/resources/app/electron-backend"

    # Copy compiled Angular frontend
    cp -r dist/apps/web "$out/lib/iptvnator/resources/app/web"

    # Copy remote control web UI
    if [ -d dist/apps/remote-control-web ]; then
      cp -r dist/apps/remote-control-web "$out/lib/iptvnator/resources/app/remote-control-web"
    fi

    # Copy workers as extraResources (electron-builder puts these outside asar)
    mkdir -p "$out/lib/iptvnator/resources"
    if [ -d dist/apps/electron-backend/workers ]; then
      cp -r dist/apps/electron-backend/workers "$out/lib/iptvnator/resources/workers"
    fi

    # Create a package.json for the app pointing to the main entry
    cat > "$out/lib/iptvnator/resources/app/package.json" <<EOF
    {
      "name": "iptvnator",
      "version": "${version}",
      "description": "IPTV player application.",
      "main": "electron-backend/main.js",
      "author": "4gray"
    }
    EOF

    # nx-electron externalizes all node_modules — copy the full tree
    # Use cp -rL to dereference pnpm's symlinks
    cp -rL node_modules "$out/lib/iptvnator/resources/app/node_modules"

    # Prune electron-builder and its deps — they're build tooling, not runtime deps
    find "$out/lib/iptvnator/resources/app/node_modules" \
      \( -name 'electron-builder' \
      -o -name 'app-builder-bin' \
      -o -name 'app-builder-lib' \
      -o -name 'dmg-builder' \
      -o -name 'electron-publish' \
      -o -name 'electron-builder-squirrel-windows' \
      \) -type d -exec rm -rf {} +

    # Wrap with system Electron
    mkdir -p "$out/bin"
    makeWrapper "${electron}/bin/electron" "$out/bin/iptvnator" \
      --add-flags "$out/lib/iptvnator/resources/app"

    # Install icons into hicolor theme (GNOME needs these)
    for size in 16 32 48 64 128 256 512; do
      icon="apps/web/src/assets/icons/icon-''${size}.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/iptvnator.png"
      fi
    done
    # Also install the large favicon variant
    if [ -f "apps/web/src/assets/icons/favicon.512x512.png" ]; then
      install -Dm644 "apps/web/src/assets/icons/favicon.512x512.png" \
        "$out/share/pixmaps/iptvnator.png"
    elif [ -f "apps/web/src/assets/icons/icon.png" ]; then
      install -Dm644 "apps/web/src/assets/icons/icon.png" \
        "$out/share/pixmaps/iptvnator.png"
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "iptvnator";
      desktopName = "IPTVnator";
      comment = "Cross-platform IPTV player application";
      exec = "iptvnator %U";
      icon = "iptvnator";
      categories = [ "AudioVideo" "Video" "Player" ];
      startupWMClass = "iptvnator";
    })
  ];

  meta = {
    description = "Cross-platform IPTV player with support for m3u/m3u8 playlists, favorites, TV guide, and more";
    homepage = "https://github.com/4gray/iptvnator";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "iptvnator";
  };
}
