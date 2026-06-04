# Debug Information Needed

When reproducing the "touchscreen disabled after returning from tablet mode" bug, please collect the following information.

## 1. Input Devices

```bash
# List all input event devices — identifies which device is the touchscreen vs pen vs uinput
cat /proc/bus/input/devices

# List xinput/libinput devices and their enabled state
libinput list-devices 2>/dev/null || xinput list
```

**Which `/dev/input/event*` device is your touchscreen (finger touch)?**
**Which `/dev/input/event*` device is your pen/stylus?**
**Is there a separate `/dev/input/event*` for the `iio-sensor-proxy` uinput SW_TABLET_MODE device?**

## 2. Uinput Device

```bash
# Confirm uinput is loaded and accessible
ls -la /dev/uinput

# After iio-sensor-proxy starts, find its virtual input device
grep -r iio-sensor-proxy /sys/devices/virtual/input/*/name
```

## 3. Tablet Mode / Switch State

```bash
# Current SW_TABLET_MODE state for all input devices
for dev in /dev/input/event*; do
  echo "=== $dev ==="
  evtest --query "$dev" EV_SW SW_TABLET_MODE 2>/dev/null && echo "  supports SW_TABLET_MODE" || echo "  no SW_TABLET_MODE"
done

# Or use evtest interactively on the uinput device to watch transitions
# evtest /dev/input/eventNN   (pick the iio-sensor-proxy one)
```

## 4. IIO Sensor Proxy D-Bus State

```bash
# Current D-Bus properties (TabletMode, HingeAngle, HasHingeAngle)
busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy TabletMode
busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy HingeAngle
busctl get-property net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy HasHingeAngle

# Monitor D-Bus property changes live
busctl monitor net.hadess.SensorProxy
```

## 5. Hinge Angle / Accelerometer sysfs

```bash
# List IIO devices
ls -la /sys/bus/iio/devices/

# For each iio device, show what it is
for d in /sys/bus/iio/devices/iio:device*; do
  echo "=== $d ==="
  cat "$d/name" 2>/dev/null
  ls "$d"/in_accel_* 2>/dev/null
  ls "$d"/in_angl_* 2>/dev/null
done
```

**Which `/sys/bus/iio/devices/iio:device*` are the display and base accelerometers?**
**Is there a dedicated hinge angle IIO device, or is it computed from dual accelerometers?**

## 6. Lid State

```bash
# What logind thinks about the lid
busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed
```

## 7. Journal Logs During Reproduction

```bash
# Capture iio-sensor-proxy logs with the debug logging enabled
# (rebuild with the patched overlay first)
sudo journalctl -u iio-sensor-proxy -f --no-pager &
sudo journalctl -u watch-sensors -f --no-pager &

# Now: fold into tablet mode, wait, fold back to laptop mode
# Then Ctrl+C the journal follow and paste the output
```

## 8. GNOME / Desktop Tablet Mode State (if using GNOME)

```bash
# Check if GNOME thinks it's in tablet mode
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.freedesktop.DBus.Properties.Get org.gnome.Shell TabletModeEnabled 2>/dev/null

# Check libinput device state for the touchscreen after returning from tablet
libinput list-devices 2>/dev/null | grep -A5 -i touch
```
