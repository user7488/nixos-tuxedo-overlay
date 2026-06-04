# Better IPTV — NixOS Package

Modern IPTV player (Tauri + MPV) built from source.

## Files

- **`better-iptv-2.6.1.tar.gz`**: Upstream source tarball.
- **`overlays/better-iptv/default.nix`**: Nixpkgs overlay adding `pkgs.better-iptv`.
- **`overlays/better-iptv/package.nix`**: Package derivation (compiles from source via `rustPlatform.buildRustPackage` + `cargo-tauri`).
- **`modules/better-iptv/default.nix`**: NixOS module with `programs.better-iptv.enable` option.
- **`PKGBUILD.txt`**: Upstream Arch Linux PKGBUILD for reference only.

## Installation

### Which option to pick?

- **Module** — handles everything for you: applies the overlay, adds `better-iptv` and `mpv` to system packages, and enables GPU/EGL drivers. Use this unless you have a reason not to.
- **Overlay only** — gives you the package without any system-level config. Pick this if you manage system packages and hardware settings yourself, or if you're using it in a flake / home-manager setup where you only need the derivation.

### Option A: Module (recommended)

```nix
# /etc/nixos/configuration.nix
{
  imports = [
    ./better-iptv/modules/better-iptv
  ];

  programs.better-iptv.enable = true;
}
```

### Option B: Overlay only

```nix
# /etc/nixos/configuration.nix
{
  nixpkgs.overlays = [
    (import ./better-iptv/overlays/better-iptv)
  ];

  environment.systemPackages = with pkgs; [ better-iptv mpv ];
}
```

## Troubleshooting

### `Could not create default EGL display: EGL_BAD_PARAMETER. Aborting...`

The package already works around this by setting `WEBKIT_DISABLE_DMABUF_RENDERER=1` and `WEBKIT_DISABLE_COMPOSITING_MODE=1` via `wrapProgram` in `package.nix`. If you still hit this error, make sure `hardware.graphics.enable = true;` is set (the module does this automatically) and that your GPU drivers are installed.

## Updating

1. Download the new source tarball from [GitHub releases](https://github.com/mewset/better-iptv/releases) (or `git archive`).
2. Place it as `better-iptv-<version>.tar.gz` in this directory.
3. Update `version`, `src`, `cargoHash`, and `npmDeps` hash in `package.nix`.
4. Run `sudo nixos-rebuild switch`.
