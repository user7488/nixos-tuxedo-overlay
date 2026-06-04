{ config, lib, pkgs, ... }:

{
  options.programs.iptvnator = {
    enable = lib.mkEnableOption "IPTVnator IPTV player";
  };

  config = lib.mkIf config.programs.iptvnator.enable {
    nixpkgs.overlays = [
      (import ../../overlays/iptvnator)
    ];

    environment.systemPackages = with pkgs; [
      iptvnator
      # Optional media players — uncomment as needed
      # mpv
      # vlc
      # ffmpeg
    ];

    # Ensure GPU/EGL drivers are available (needed by Electron)
    hardware.graphics.enable = lib.mkDefault true;
  };
}
