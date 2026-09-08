{
  config,
  lib,
  pkgs,
  ...
}:

{

  environment.systemPackages = with pkgs; [

    # webcam support, v4l2-ctl --list-devices
    v4l-utils

    # head tracking
    opentrack

    (writeScriptBin "opentrack-xwayland" ''
      #!/usr/bin/env bash
      # get the logitech c920s (with IR filter removed) ready for opentrack with Input PointTracker 1.1.

      # get correct /dev/videoX from v4l2-ctl
      d=$(v4l2-ctl --list-devices | grep -A1 "HD Pro Webcam" | tail -1 | tr -d '\t')
      echo video device: $d
      env -u WAYLAND_DISPLAY opentrack &

      # must use <60 gain for logitech c920s to manage ~60fps;
      # why u say? it needs to happen a little later. i have no idea.
      opentrack_pid=$!
      { while kill -0 $opentrack_pid 2>/dev/null; do
        v4l2-ctl -d $d -c brightness=0;
        v4l2-ctl -d $d -c contrast=0;
        v4l2-ctl -d $d -c saturation=0;
        v4l2-ctl -d $d -c sharpness=0;
        v4l2-ctl -d $d -c white_balance_automatic=0;
        v4l2-ctl -d $d -c backlight_compensation=0;
        v4l2-ctl -d $d -c exposure_dynamic_framerate=0;
        v4l2-ctl -d $d -c auto_exposure=1;
        v4l2-ctl -d $d -c pan_absolute=0;
        v4l2-ctl -d $d -c tilt_absolute=0;
        v4l2-ctl -d $d -c focus_automatic_continuous=0;
        v4l2-ctl -d $d -c focus_absolute=40;
        #v4l2-ctl -d $d -c zoom_absolute=195;
        v4l2-ctl -d $d -c zoom_absolute=310;
        v4l2-ctl -d $d -c gain=39;
        v4l2-ctl -d $d -c white_balance_temperature=2000;
        v4l2-ctl -d $d -c exposure_time_absolute=9;
        sleep 5;
        done; } &
      wait
    '')

    # Listens (read-only, never grabs) on the VKBSim Gunfighter for one
    # specific button and relays it as a "Z" keypress - matches the key
    # bound in opentrack to reset/center its view. Doesn't touch the real
    # joystick device, so it keeps working normally for MSFS/DCS bindings.
    (writeScriptBin "gunfighter-z-relay" ''
      #!/usr/bin/env nix-shell
      #!nix-shell -i python3 -p "python3.withPackages (ps: [ ps.evdev ])"
      import time
      import evdev
      from evdev import UInput, ecodes as e

      DEVICE_PATH = "/dev/input/by-id/usb-VKB-Sim__C__Alex_Oz_2023_VKBSim_Gunfighter_MCG_Ultimate-event-joystick"
      TRIGGER_CODE = 294  # BTN_BASE

      def send_z(ui):
          ui.write(e.EV_KEY, e.KEY_Z, 1)
          ui.syn()
          ui.write(e.EV_KEY, e.KEY_Z, 0)
          ui.syn()

      def run():
          ui = UInput({e.EV_KEY: [e.KEY_Z]}, name="gunfighter-z-relay")
          while True:
              try:
                  dev = evdev.InputDevice(DEVICE_PATH)
                  print(f"Listening on {dev.name}")
                  for event in dev.read_loop():
                      if event.type == e.EV_KEY and event.code == TRIGGER_CODE and event.value == 1:
                          send_z(ui)
              except OSError as ex:
                  print(f"Device unavailable ({ex}), retrying in 5s...")
                  time.sleep(5)

      if __name__ == "__main__":
          run()
    '')
  ];
}
