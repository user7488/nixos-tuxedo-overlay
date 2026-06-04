{ config, lib, pkgs, ... }:

{
  options.programs.better-iptv = {
    enable = lib.mkEnableOption "Better IPTV player";
  };

  config = lib.mkIf config.programs.better-iptv.enable {
    nixpkgs.overlays = [
      (import ../../overlays/better-iptv)
    ];

    # Include better-iptv and its runtime dependency mpv
    environment.systemPackages = [ pkgs.better-iptv pkgs.mpv ];

    # Ensure GPU/EGL drivers are available (needed by WebKitGTK)
    hardware.graphics.enable = lib.mkDefault true;
  };
}
