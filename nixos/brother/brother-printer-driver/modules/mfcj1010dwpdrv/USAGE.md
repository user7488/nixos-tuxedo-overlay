# Brother MFC-J1010DW NixOS Driver

This directory contains a NixOS module for the Brother MFC-J1010DW printer driver.

## Files

- `driver.nix`: The Nix package derivation for the driver.
- `module.nix`: The NixOS module that enables the driver and handles unfree license configuration.
- `mfcj1010dwpdrv-3.5.0-1.i386.rpm`: The driver source file.

## Usage

### 1. Copy to your NixOS configuration

Copy this entire directory to your NixOS configuration directory (e.g., `/etc/nixos/modules/mfcj1010dwpdrv`).

### 2. Import the module

Add the path to `module.nix` to the `imports` list in your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./modules/mfcj1010dwpdrv/module.nix  # Adjust path as necessary
  ];

  # ... rest of your configuration
}
```

### 3. Rebuild

Rebuild your system:

```bash
sudo nixos-rebuild switch
```

### 4. Add Printer

1. Open the CUPS interface at [http://localhost:631](http://localhost:631).
2. Go to **Administration** -> **Add Printer**.
3. Select your Brother printer (e.g., "Brother MFC-J1010DW").
4. When asked for the **Model**, select **Brother MFC-J1010DW CUPS (en)**.

## Troubleshooting

If the printer is not detected or printing fails:
1. Ensure the printer is connected and on the same network (or USB).
2. Check `journalctl -u cups` for errors.
3. Verify that the driver files are present in `/nix/store/...-mfcj1010dwpdrv-.../opt/brother/...`.

## Manual Build (Optional)

To build the driver manually for testing without switching your system:

```bash
nix-build -E 'with import <nixpkgs> { config.allowUnfree = true; }; callPackage ./driver.nix {}'
```
