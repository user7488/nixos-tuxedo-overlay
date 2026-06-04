# Brother MFC-J1010DW — NixOS Printer Driver

Driver for the Brother MFC-J1010DW (print only; scanner RPMs are present but not yet packaged).

## Files

- **`brother-printer-driver/modules/mfcj1010dwpdrv/driver.nix`**: Nix derivation that unpacks the RPM, patches the Perl filter scripts and CUPS wrapper, and installs the PPD.
- **`brother-printer-driver/modules/mfcj1010dwpdrv/module.nix`**: NixOS module that registers the driver with CUPS and allows the unfree package.
- **`brother-printer-driver/modules/mfcj1010dwpdrv/mfcj1010dwpdrv-3.5.0-1.i386.rpm`**: Upstream driver RPM (bundled, no download needed).
- **`brother-printer-driver/WORKDIR/`**: Scratch directory with the unpacked RPM contents (reference only).
- **`brother-printer-driver/NOTES/`**: Packaging notes.
- **`brscan5-*.rpm`, `brscan-skey-*.rpm`, `brmfcfaxdrv-*.rpm`, `brother-udev-rule-type1-*.rpm`**: Scanner / fax / udev RPMs — **not yet packaged for NixOS**.

## Installation

### 1. Copy to your NixOS config

Copy the module directory into `/etc/nixos/modules/`:

```bash
sudo cp -r brother-printer-driver/modules/mfcj1010dwpdrv /etc/nixos/modules/
```

### 2. Import the module

Add to your `/etc/nixos/configuration.nix`:

```nix
{
  imports = [
    ./modules/mfcj1010dwpdrv/module.nix
  ];
}
```

That's it — the module automatically:
- Registers the driver with CUPS (`services.printing.drivers`).
- Allows the unfree `mfcj1010dwpdrv` package.

### 3. Rebuild

```bash
sudo nixos-rebuild switch
```

### 4. Add the printer in CUPS

1. Open [http://localhost:631](http://localhost:631).
2. **Administration → Add Printer**.
3. Select the Brother MFC-J1010DW (USB or network).
4. For **Model**, choose **Brother MFC-J1010DW CUPS (en)**.
5. Print a test page.

## Testing (without switching)

Build the driver derivation standalone to check it compiles:

```bash
cd /etc/nixos/modules/mfcj1010dwpdrv
nix-build -E 'with import <nixpkgs> { config.allowUnfree = true; }; callPackage ./driver.nix {}'
```

Inspect the result:

```bash
ls result/share/cups/model/     # should contain brother-mfcj1010dw.ppd
ls result/lib/cups/filter/      # should contain brother_lpdwrapper_mfcj1010dw
ls result/opt/brother/Printers/ # should contain mfcj1010dw/
```

## Verifying it works

After `nixos-rebuild switch` and adding the printer in CUPS:

```bash
# Check the driver is registered
lpinfo -m | grep -i brother

# Print a test page from the command line
echo "Hello Brother" | lp -d Brother_MFC_J1010DW

# If something goes wrong, check CUPS logs
journalctl -u cups -f
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| Printer not listed in CUPS | Make sure `services.printing.enable = true;` is set. Restart CUPS: `sudo systemctl restart cups`. |
| "Filter failed" in CUPS | Check `journalctl -u cups` — usually a missing runtime dep. Rebuild the driver and inspect the patched scripts in `result/opt/brother/…`. |
| Printer found but nothing prints | Verify the printer is on and reachable (`ping <ip>` or check USB with `lsusb`). |
| `allowUnfree` errors | The module handles this, but if you use flakes you may need `nixpkgs.config.allowUnfree = true;` or an equivalent predicate. |
