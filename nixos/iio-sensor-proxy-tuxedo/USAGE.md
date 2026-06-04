# Usage Guide

This directory contains configuration for the TUXEDO `iio-sensor-proxy`, `tuxedo-drivers-userspace` package, and a monitoring service.

## Files

- **`overlays/iio-sensor-proxy-tuxedo/default.nix`**: A Nixpkgs overlay that patches `iio-sensor-proxy` with TUXEDO-specific modifications.
- **`modules/watch-sensors/default.nix`**: A NixOS module that defines a systemd service (`watch-sensors`) to poll sensors.
- **`modules/tuxedo-drivers-userspace/default.nix`**: A NixOS module that packages the userspace components (udev rules, etc.) for `tuxedo-drivers`.

## Installation

To use these files in your NixOS configuration (`/etc/nixos/configuration.nix`), you need to:

1.  **Import the modules**: Add the module directories to your `imports` list.
2.  **Apply the overlay**: Add the overlay directory to your `nixpkgs.overlays` list.
3.  **Enable the service**: Enable the `tuxedo-drivers-userspace` module via its option.

### Recommended Directory Structure

It is recommended to copy the directories into `/etc/nixos/`:

*   `/etc/nixos/overlays/iio-sensor-proxy-tuxedo/`
*   `/etc/nixos/modules/watch-sensors/`
*   `/etc/nixos/modules/tuxedo-drivers-userspace/`

(You may need to create these parent directories if they don't exist: `mkdir -p /etc/nixos/{overlays,modules}`)

### Example Configuration

Add the following to your `/etc/nixos/configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  imports = [
    # ... other imports ...
    # Import modules by directory path (uses default.nix automatically)
    ./modules/watch-sensors
    ./modules/tuxedo-drivers-userspace
  ];

  nixpkgs.overlays = [
    # Import overlay by directory path
    (import ./overlays/iio-sensor-proxy-tuxedo)
  ];

  # Enable the TUXEDO drivers userspace components
  hardware.tuxedo-drivers-userspace.enable = true;

  # Optional: Enable the standard iio-sensor-proxy service if needed
  # hardware.sensor.iio.enable = true;
}
```
