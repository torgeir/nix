{
  dotfiles,
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Firefox streams whose properties contain "firefox" AND any of these
  # site keywords (case-insensitive, e.g. matched against the page title)
  # get capped at maxVolumePercent.
  sites = [
    "facebook"
    "youtube"
  ];
  maxVolumePercent = 70;

  sitesJson = builtins.toJSON sites;
  # wpctl wants a 0..1 fraction.
  targetFrac = toString (maxVolumePercent / 100.0);

  firefox-max-volume = pkgs.writeShellApplication {
    name = "firefox-max-volume";
    runtimeInputs = [
      pkgs.pipewire # pw-dump
      pkgs.wireplumber # wpctl
      pkgs.pulseaudio # pactl (event source only)
      pkgs.jq
      pkgs.gawk
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      TARGET="${targetFrac}"
      SITES='${sitesJson}'
      POLL=1

      # IMPORTANT: read titles from pw-dump, not `pactl list sink-inputs`.
      # The pulse view reports paused/just-started Firefox streams as
      # "(null)"/"AudioStream" and never shows the page title, so YouTube
      # never matched. pw-dump (the native view pavucontrol uses) keeps the
      # real "... - YouTube" / "(11) Facebook" title. We then set the cap by
      # node id with wpctl.
      apply() {
        pw-dump | jq -r --argjson sites "$SITES" '
          .[]
          | select(.type == "PipeWire:Interface:Node")
          | select(.info.props."media.class" == "Stream/Output/Audio")
          | . as $n
          | ([$n.info.props | to_entries[].value | tostring | ascii_downcase]
             | join(" ")) as $blob
          | select($blob | test("firefox"))
          | select(any($sites[]; . as $s | $blob | test($s)))
          | $n.id
        ' | while read -r id; do
          # Cap only: lower it if it is above TARGET, never raise it.
          cur=$(wpctl get-volume "$id" 2>/dev/null | awk '{print $2}')
          if awk "BEGIN { exit !((''${cur:-1}) > $TARGET) }"; then
            wpctl set-volume "$id" "$TARGET" || true
          fi
        done
      }

      # Safety-net poller: the page title (our match signal) often resolves
      # after the stream is created, without emitting a pactl event.
      while true; do
        apply
        sleep "$POLL"
      done &

      # Event-driven: react immediately to stream add/change/volume events.
      apply
      pactl subscribe | grep --line-buffered "sink-input" | while read -r _; do
        apply
      done
    '';
  };
in
{
  home.packages = [ firefox-max-volume ];

  systemd.user.services.firefox-max-volume = {
    Unit = {
      Description = "Cap Firefox streams for configured sites at a max volume";
      After = [
        "pipewire.service"
        "pipewire-pulse.service"
        "wireplumber.service"
      ];
      PartOf = [ "default.target" ];
    };
    Service = {
      ExecStart = "${firefox-max-volume}/bin/firefox-max-volume";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
