{ config, lib, pkgs, ... }:

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
  ];
}
