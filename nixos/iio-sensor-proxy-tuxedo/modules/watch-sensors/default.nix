{ config, lib, pkgs, ... }:

{
  systemd.services.watch-sensors = {
    description = "Poll Sensors Service";
    documentation = [ "https://deb.tuxedocomputers.com/ubuntu/pool/main/i/iio-sensor-proxy/" ];
    
    # Matches the [Unit] part of the original service file
    after = [ "iio-sensor-proxy.service" ];
    wants = [ "iio-sensor-proxy.service" ];

    # Matches the [Service] part
    serviceConfig = {
      Type = "exec";
      # specific absolute path to the binary from the package
      ExecStart = "${pkgs.iio-sensor-proxy}/bin/monitor-sensor";
      Restart = "on-failure";
    };

    # Matches the [Install] part
    wantedBy = [ "multi-user.target" ];
  };

  # Tuxedo InfinityFlex sensor orientation fixes are provided by tuxedo-drivers
  services.udev.packages = [ config.boot.kernelPackages.tuxedo-drivers ];
}
