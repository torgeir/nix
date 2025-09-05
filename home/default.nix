{ dotfiles, config, lib, pkgs, inputs, ... }:

let
in {

  imports = [
    ./audio-production.nix
    ./gtk.nix
    ./fonts.nix
    ./gpg.nix
    ./gaming.nix
    ./file-manager.nix
    (inputs.nix-home-manager + "/modules")
  ];

  programs.t-doomemacs.enable = true;
  programs.t-nvim.enable = true;
  programs.t-terminal.alacritty.enable = true;
  programs.t-zoxide.enable = true;
  programs.t-git.enable = true;
  programs.t-shell-tooling.enable = true;
  programs.t-tmux.enable = true;
  programs.t-sway = {
    enable = true;
    statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs";
    extraConfig = let
        term = "alacritty";
        status_term_font_size = "10";
      in ''

      default_border pixel 5
      default_floating_border normal
      client.focused #00aaff #ff00aa #00ffaa

      output DP-2 {
        bg ~/.config/bg.jpg fill
        position 0,0
        transform 0

        # 2023-05-01: freesync still flickers on the
        # 'Samsung Electric Company C32HG7x H4ZM800200'
        #adaptive_sync on
        adaptive_sync off

        #mode 1920x1080@120Hz
        #mode 2560x1440@99.946Hz
        mode 2560x1440@143.998Hz
      }
      output DP-1 {
        # torgeir: this is buggy with sway, sept 2022
        # torgeir: still not ok, 2023-01
        # torgeir: still not ok, 2023-08
        #position 2560,-1150
        #position 0,0
        bg ~/.config/bg.jpg fill
        transform 270
        mode 2560x1440@59.951Hz
      }
      workspace 1 output DP-2
      workspace 2 output DP-2
      workspace 3 output DP-2
      workspace 4 output DP-2
      workspace 5 output DP-2
      workspace  6 output DP-1
      workspace  7 output DP-1
      workspace  8 output DP-1
      workspace  9 output DP-1
      workspace 10 output DP-1

      # Window classes (swaymsg -t get_tree | rg class)
      # Lookup windows: https://gist.github.com/dshoreman/278091a17c08e30c46c7e7988b7c2f7d
      # What goes where

      for_window [title="Picture-in-Picture"] floating disable; sticky enable; move window to workspace number 9; resize set height 1600px;
      #border none; resize set width 720px; move position 600px 2000px;

      assign [app_id="emacs"] 2
      assign [app_id="org.rncbc.qpwgraph"] 4

      assign [class="REAPER"] 3
      for_window [class="REAPER"] floating disable
      for_window [class="REAPER" title="REAPER Query"] floating enable
      for_window [class="REAPER" title="REAPER \(loading\)"] floating enable
      for_window [class="REAPER" title="REAPER \(initializing\)"] floating enable
      for_window [class="REAPER" title="Project Load Warning"] floating enable
      for_window [class="REAPER" title="^Routing.*"] floating enable
      for_window [class="REAPER" title="^Build.*"] floating enable
      for_window [class="REAPER" title="^Controls.*"] floating enable
      for_window [class="REAPER" title="^Choose.*"] floating enable
      for_window [class="REAPER" title="^Import.*"] floating enable
      for_window [class="REAPER" title="FX"] floating enable
      for_window [class="REAPER" title="^LV2.*"] floating enable
      for_window [class="REAPER" title=".*JS.*"] floating enable
      for_window [class="REAPER" title="^VST.*"] floating enable
      for_window [class="REAPER" title="^VST.*"] floating enable
      for_window [class="REAPER" title=".*Helix.*"] floating disable

      assign [title="term-journalctl"] 6
      assign [title="^CoreCtrl"] 6
      for_window [title="term-journalctl"] resize set height 1560px
      for_window [title="CoreCtrl"] resize set height 1000px

      assign [app_id="net.nokyan.Resources"] 7
      assign [title="term-top"] 7
      for_window [title="Resources"] resize set height 1660px
      for_window [title="term-top"] resize set height 900px

      ##
      ## gaming
      ##
      assign [class="steam"] 5
      assign [class="steam_app.*"] 5
      # assign [instance="steam"] 5
      # assign [title=".*[sS]team.*"] 5
      for_window [class="^steam_app.*"] move window to workspace number 5
      for_window [class="steam_app.*"] fullscreen enable
      for_window [class="steam_app.*"] inhibit_idle focus

      assign [title="^DCS.*"] 5
      assign [title="^Digital Combat Simulator.*"] 5

      assign [title="^opentrack.*"] 6
      assign [title="^Mapping.*"] 6
      assign [title="^Options.*"] 6
      for_window [app_id="opentrack"] floating enable
      for_window [app_id="qv4l2"] floating enable
      for_window [title="^opentrack.*"] fullscreen disable; floating enable; move window to workspace number 6
      for_window [title="^Mapping.*"] fullscreen disable; floating enable; move window to workspace number 6
      for_window [title="^Options.*"] fullscreen disable; floating enable; move window to workspace number 6

      # FH5: move the black window off screen
      # FH5: keep the one with the game
      assign [class="steam_app_1551360"] 2
      assign [title="Forza Horizon 5"] 1
      for_window [class="steam_app_1551360"] move window to workspace number 2
      for_window [title="Forza Horizon 5"] move window to workspace number 1

      for_window [title="EFB"] move window to workspace number 9; resize set height 405px; resize set width 320px; move position 800px 2000px

      assign [class="Signal"] 8
      assign [app_id="Slack"] 8
      assign [title="Spotify Premium"] 8

      # https://github.com/signalapp/Signal-Desktop/issues/5719
      #for_window [app_id="signal"] floating enable
      #assign [app_id="signal*"] 6
      #exec "signal-desktop --ozone-platform=wayland"

      workspace 6
      exec "${term} --title term-journalctl -o font.size=${status_term_font_size} -e journalctl -f "
      exec "corectrl"

      workspace 7
      exec "${term} --title term-top -o font.size=${status_term_font_size} -e btop"
      exec 'resources'

      workspace 8
      exec dropbox
      exec spotify

      exec qpwgraph -stylesheet ~/.config/dotfiles/config/qpwgraph/style.qss ~/graph-setup.qpwgraph
      exec $browser
      exec emacs ~/nixos-config/configuration.nix
    '';
  };
  programs.t-firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    #package = pkgs.firefox-devedition-bin;
    legacyExtensions = false;
  };

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    nerd-fonts.iosevka
    nerd-fonts.iosevka-term

    resources

    # tools
    killall

    # images
    imagemagick
    gnuplot

    #https://nixos.wiki/wiki/Samba

    # formats
    flac

    # apps
    mpv
    #mpc-cli
    ncmpcpp # mpd music player

    signal-desktop
    spotify
    slack
    dropbox

    # sound
    pavucontrol
    qpwgraph

    # sudo -EH rpi-imager
    rpi-imager

    # wallpapers
    # https://github.com/natpen/awesome-wayland#wallpaper

    # vst/audio-production
    reaper
    # helix native needs wine with fsync patches
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    (pkgs.stable.yabridge.override {
      wine = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    })
    (pkgs.stable.yabridgectl.override {
      wine = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    })
    winetricks
    dxvk_2
  ];

  # this puts files in the needed locations, but does however not make them
  # editable allows interop with torgeir/dotfiles.git without moving all this
  # configuration to .nix files
  home.file = {
    ".local/bin/reaper-low-latency".source =
      pkgs.writeShellScript "launch-reaper-low-latency" ''
        # make firefox play nice, not to hinder realtime audio
        pgrep -f -w firefox | xargs renice --relative 5 {}
        PIPEWIRE_QUANTUM=48/48000 ${pkgs.reaper}/bin/reaper
      '';

    ".local/bin/sway-refresh-displays".source =
      pkgs.writeShellScript "sway-refresh-displays" ''
        swaymsg "output * dpms off"
        sleep 2
        swaymsg "output * dpms on"
      '';

    ".config/dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles
      + "/config/corectrl/corectrl.ini";
  };

  # sops with home manager is a little different, see configuration.nix
  #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #   sops.age.keyFile = "/etc/nix-sops-secret.key";
  #   sops.secrets."smb".owner = "torgeir";

  home.stateVersion = "23.11";

}
