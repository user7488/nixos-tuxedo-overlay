# IPTVnator — NixOS Package

Cross-platform IPTV player (Electron 39 + Angular, Nx monorepo) built from source.

## Files

- **`overlays/iptvnator/default.nix`**: Nixpkgs overlay adding `pkgs.iptvnator`.
- **`overlays/iptvnator/package.nix`**: Package derivation (builds from source with pnpm + Electron).
- **`modules/iptvnator/default.nix`**: NixOS module with `programs.iptvnator.enable` option.
- **`PKGBUILD.txt`**: Upstream Arch Linux PKGBUILD for reference only.

## First-time setup — filling in the pnpm deps hash

The source hash is already filled in. The `pnpmDeps` hash still uses `lib.fakeHash` as a placeholder:

1. Run `sudo nixos-rebuild switch` — it will fail on the pnpm deps hash and print the correct one.
2. Replace the `lib.fakeHash` in `pnpmDeps` inside `package.nix` with the printed hash.
3. Run `sudo nixos-rebuild switch` again.

You may also need to adjust runtime `node_modules` copying in `installPhase` if modules are missing at runtime.

## Installation

### Option A: Module (recommended)

```nix
# /etc/nixos/configuration.nix
{
  imports = [
    ./iptvnator/modules/iptvnator
  ];

  programs.iptvnator.enable = true;
}
```

### Option B: Overlay only

```nix
# /etc/nixos/configuration.nix
{
  nixpkgs.overlays = [
    (import ./iptvnator/overlays/iptvnator)
  ];

  environment.systemPackages = with pkgs; [ iptvnator ];
}
```

## Optional dependencies

IPTVnator can use external media players. Install them separately:

```nix
environment.systemPackages = with pkgs; [ mpv vlc ffmpeg ];
```

## Updating

1. Check the [latest release](https://github.com/4gray/iptvnator/releases).
2. Update `version` in `package.nix`.
3. Re-fetch the `src` hash: `nix-prefetch-github 4gray iptvnator --rev v<new-version>`.
4. Clear and re-derive the `pnpmDeps` hash (set to `lib.fakeHash`, rebuild, copy printed hash).
5. Run `sudo nixos-rebuild switch`.
