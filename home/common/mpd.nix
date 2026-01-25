{
  config,
  lib,
  pkgs,
  ...
}:

{

  home.packages = with pkgs; [
    mpc # used for i3status-rust
  ];

  # rmpc player
  programs.rmpc.enable = true;
  # mpd music player
  programs.ncmpcpp.enable = true;

  # mpd
  services.mako.enable = true;
  services.mpdris2 = {
    enable = true;
    notifications = true;
  };
  systemd.user.services.mpdris2.Service.Environment =
    "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus";
  services.mpd = {
    enable = true;
    musicDirectory = "/run/mount/music";
    extraConfig = ''
      audio_output {
         type "pipewire"
         name "PipeWire Sound Server"
       }
    '';
  };
}
