final: prev: {
  iio-sensor-proxy = prev.iio-sensor-proxy.overrideAttrs (old: {
    version = "3.5-5tux1";

    # Use vanilla 3.5 as base from local file
    src = prev.runCommand "iio-sensor-proxy-3.5.tar.gz" {
      outputHashMode = "flat";
      outputHashAlgo = "sha256";
      outputHash = "sha256-holCXyKHYmqV2VseHlti5JfQndCM9BEITtIhZtSknaU=";
    } ''
      cp ${./iio-sensor-proxy-3.5.tar.gz} $out
    '';

    # Use local TUXEDO patch
    patches = [
      (prev.runCommand "iio-sensor-proxy-base35.patch" {
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = "sha256-rdqlvEM3yNo0LDrMFjE19ugbzLAkVcznwjNfWkNXu3g=";
      } ''
        cp ${./iio-sensor-proxy-base35.patch} $out
      '')
    ];

    # Ensure patches apply cleanly
    patchFlags = [ "-p1" "-d" "." ];

    postPatch = ''
      # Fix hardcoded paths in the Tuxedo patch which uses system() calls
      substituteInPlace src/iio-sensor-proxy.c \
        --replace 'busctl ' '${prev.systemd}/bin/busctl ' \
        --replace 'grep ' '${prev.gnugrep}/bin/grep '

      # Add verbose debug logging around tablet mode transitions
      # 1. Log the full busctl|grep command and its exit code in lid_is_closed()
      substituteInPlace src/iio-sensor-proxy.c \
        --replace \
          'exit_code = system ("busctl get-property org.freedesktop.login1 /org/freedesktop/login1 "
			   "org.freedesktop.login1.Manager LidClosed | grep true");

	return !exit_code;' \
          'g_message ("DEBUG lid_is_closed: running busctl|grep to check LidClosed");
	exit_code = system ("${prev.systemd}/bin/busctl get-property org.freedesktop.login1 /org/freedesktop/login1 "
			   "org.freedesktop.login1.Manager LidClosed | ${prev.gnugrep}/bin/grep true");
	g_message ("DEBUG lid_is_closed: busctl|grep exit_code=%d => lid_closed=%s", exit_code, !exit_code ? "TRUE" : "FALSE");
	return !exit_code;'

      # 2. Log tablet mode transitions with full context in hinge_angle_changed_func
      substituteInPlace src/iio-sensor-proxy.c \
        --replace \
          'tablet_mode = calc_tablet_mode (readings->angle);
	if (data->previous_tablet_mode != tablet_mode) {
		TabletMode tmp;

		tmp = data->previous_tablet_mode;
		data->previous_tablet_mode = tablet_mode;

		mask |= PROP_TABLET_MODE;
		g_debug ("Emitting tablet mode changed: from %s to %s",
			 tablet_mode_to_str (tmp),
			 tablet_mode_to_str (data->previous_tablet_mode));

		emit_uinput_event (data, EV_SW, SW_TABLET_MODE,
				tablet_mode == TABLET_MODE_TABLET);
		emit_uinput_event (data, EV_SYN, SYN_REPORT, 0);
	}' \
          'tablet_mode = calc_tablet_mode (readings->angle);
	g_message ("DEBUG tablet_mode_check: angle=%.1f calc_mode=%s prev_mode=%s uinput_fd=%d",
		   readings->angle, tablet_mode_to_str (tablet_mode),
		   tablet_mode_to_str (data->previous_tablet_mode), data->uinput_fd);
	if (data->previous_tablet_mode != tablet_mode) {
		TabletMode tmp;

		tmp = data->previous_tablet_mode;
		data->previous_tablet_mode = tablet_mode;

		mask |= PROP_TABLET_MODE;
		g_message ("DEBUG TABLET_MODE_TRANSITION: %s -> %s (angle=%.1f, uinput_fd=%d, SW_TABLET_MODE val=%d)",
			   tablet_mode_to_str (tmp),
			   tablet_mode_to_str (data->previous_tablet_mode),
			   readings->angle, data->uinput_fd,
			   tablet_mode == TABLET_MODE_TABLET);

		emit_uinput_event (data, EV_SW, SW_TABLET_MODE,
				tablet_mode == TABLET_MODE_TABLET);
		emit_uinput_event (data, EV_SYN, SYN_REPORT, 0);
	}'

      # 3. Log uinput write results in emit_uinput_event
      substituteInPlace src/iio-sensor-proxy.c \
        --replace \
          'write (data->uinput_fd, &ev, sizeof(ev));' \
          '{
		ssize_t written = write (data->uinput_fd, &ev, sizeof(ev));
		if (written < 0)
			g_warning ("DEBUG uinput_write FAILED: type=%d code=%d val=%d errno=%d (%s)",
				   type, code, val, errno, strerror (errno));
		else
			g_message ("DEBUG uinput_write OK: type=%d code=%d val=%d bytes=%zd",
				   type, code, val, written);
	}'

      # 4. Log uinput device setup result
      substituteInPlace src/iio-sensor-proxy.c \
        --replace \
          'data->uinput_fd = fd;

	return TRUE;' \
          'data->uinput_fd = fd;
	g_message ("DEBUG uinput_setup: device created successfully, fd=%d", fd);
	return TRUE;'

      # 5. Log hinge angle calculation details in calc_accel_hinge_angle
      substituteInPlace src/iio-sensor-proxy.c \
        --replace \
          'if (lid_closed)
		hinge_angle = 0;
	else if (hinge_angle < 15)
		hinge_angle = 360;

	//FIXME: Add data validations to filter invalid values caused by vibration
	g_debug ("Hinge angle is %.1f degrees", hinge_angle);' \
          'g_message ("DEBUG calc_hinge: raw=%.1f 2d=%.1f 3d=%.1f lid_closed=%d",
		   hinge_angle, hinge_angle2d, hinge_angle3d, lid_closed);
	if (lid_closed)
		hinge_angle = 0;
	else if (hinge_angle < 15)
		hinge_angle = 360;

	g_message ("DEBUG calc_hinge: final_angle=%.1f (after lid/wrap adjustment)", hinge_angle);'

      # Fix polkit policy directory installation
      substituteInPlace meson.build \
        --replace "polkit_gobject_dep.get_pkgconfig_variable('policydir')" \
                  "get_option('datadir') / 'polkit-1' / 'actions'"
    '';

    # Keep other build dependencies from original
    buildInputs = old.buildInputs;
    nativeBuildInputs = old.nativeBuildInputs;
  });
}
