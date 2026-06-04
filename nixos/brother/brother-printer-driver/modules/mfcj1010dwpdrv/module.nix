{ config, lib, pkgs, ... }:

let
  # Import the driver package derivation
  driver = pkgs.callPackage ./driver.nix {};
in
{
  # Add the driver to CUPS
  services.printing.drivers = [ driver ];

  # Automatically allow this unfree package
  nixpkgs.config.allowUnfreePredicate = pkg: 
    builtins.elem (lib.getName pkg) [ "mfcj1010dwpdrv" ];
}
