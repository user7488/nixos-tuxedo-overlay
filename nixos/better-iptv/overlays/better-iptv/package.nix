{
  lib,
  stdenv,
  rustPlatform,
  cargo-tauri,
  pkg-config,
  wrapGAppsHook3,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  webkitgtk_4_1,
  gtk3,
  glib,
  glib-networking,
  libsoup_3,
  openssl,
  libappindicator-gtk3,
  librsvg,
  gdk-pixbuf,
  cairo,
  pango,
  atk,
  dbus,
  mpv,
  gsettings-desktop-schemas,
  mesa,
  libGL,
  libglvnd,
  egl-wayland,
  vulkan-loader,
}:

let
  pname = "better-iptv";
  version = "2.6.1";

  src = ./../../better-iptv-2.6.1.tar.gz;

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    inherit src;
    sourceRoot = "better-iptv-${version}";
    hash = "sha256-/jyT6gAUPWrNY91ReeEjdKwuQEJQy1JLmPIBWKa85WE=";
  };
in
rustPlatform.buildRustPackage {
  inherit pname version src;

  sourceRoot = "better-iptv-${version}/src-tauri";

  useFetchCargoVendor = true;
  cargoHash = "sha256-t+4ifayXeTa9jIEgauGziy7OG2LhTXrckjaARUcT+nA=";

  nativeBuildInputs = [
    cargo-tauri.hook
    pkg-config
    wrapGAppsHook3
    npmHooks.npmConfigHook
    nodejs
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    glib
    glib-networking
    gdk-pixbuf
    cairo
    pango
    atk
    libsoup_3
    openssl
    libappindicator-gtk3
    librsvg
    dbus
    gsettings-desktop-schemas
    # EGL / GPU
    mesa
    libGL
    libglvnd
    egl-wayland
    vulkan-loader
  ];

  tauriBuildFlags = [ ];

  # npmConfigHook needs these
  inherit npmDeps;
  npmRoot = "..";

  # Ensure WebKit EGL workaround + mpv in PATH
  postFixup = ''
    wrapProgram $out/bin/better-ip-tv \
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1 \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --prefix PATH : ${lib.makeBinPath [ mpv ]} \
      --prefix LIBGL_DRIVERS_PATH : /run/opengl-driver/lib/dri \
      --prefix __EGL_VENDOR_LIBRARY_DIRS : /run/opengl-driver/share/glvnd/egl_vendor.d
  '';

  postInstall = ''
    # Install desktop file
    install -Dm644 templates/better-iptv.desktop \
      $out/share/applications/better-iptv.desktop
    substituteInPlace $out/share/applications/better-iptv.desktop \
      --replace-quiet "{{{name}}}" "Better IPTV" \
      --replace-quiet "{{#if comment}}" "" \
      --replace-quiet "{{{comment}}}" "Modern IPTV player" \
      --replace-quiet "{{/if}}" "" \
      --replace-quiet "Exec=env WEBKIT_DISABLE_DMABUF_RENDERER=1 {{{exec}}}" \
                      "Exec=$out/bin/better-ip-tv" \
      --replace-quiet "{{{icon}}}" "better-iptv" \
      --replace-quiet "{{{categories}}}" "AudioVideo;Video;Player;" \
      --replace-quiet "StartupWMClass={{{name}}}" "StartupWMClass=Better IPTV"

    # Install icons
    install -Dm644 icons/32x32.png \
      $out/share/icons/hicolor/32x32/apps/better-iptv.png
    install -Dm644 icons/128x128.png \
      $out/share/icons/hicolor/128x128/apps/better-iptv.png
    install -Dm644 icons/icon.png \
      $out/share/pixmaps/better-iptv.png
  '';

  meta = {
    description = "Modern, powerful IPTV player for Linux (Tauri + MPV)";
    homepage = "https://github.com/mewset/better-iptv";
    license = lib.licenses.gpl2;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "better-ip-tv";
  };
}
