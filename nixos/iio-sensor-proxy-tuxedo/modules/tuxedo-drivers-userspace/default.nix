{ config, lib, pkgs, ... }:

let
  tuxedoDriversUserspace = pkgs.callPackage ./package.nix { };
in
{
  options.hardware.tuxedo-drivers-userspace = {
    enable = lib.mkEnableOption "TUXEDO drivers userspace components";
  };

  config = lib.mkIf config.hardware.tuxedo-drivers-userspace.enable {
    environment.systemPackages = [ tuxedoDriversUserspace ];
    services.udev.packages = [ tuxedoDriversUserspace ];
  };
}
