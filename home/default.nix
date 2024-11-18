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
    extraConfig = let term = "alacritty";
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

      for_window [title="Picture-in-Picture"] floating enable sticky enable border none

      assign [class="Brave-browser"] 1
      for_window [class="Brave-browser" title="Picture in picture"] floating enable sticky enable border none

      # assign [class="Emacs"] 2

      assign [class="REAPER"] 3
      for_window [class="REAPER"] floating disable
      for_window [class="REAPER" title=".*Helix.*"] floating disable
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

      assign [title="term-journalctl"] 6
      assign [title="^CoreCtrl"] 6
      for_window [title="term-journalctl"] resize set height 1560px
      for_window [title="CoreCtrl"] resize set height 1000px

      assign [title="^Resources"] 7
      assign [title="term-top"] 7
      for_window [title="Resources"] resize set height 1660px
      for_window [title="term-top"] resize set height 900px

      ##
      ## gaming
      ##
      ## hack to fake disabled vsync
      for_window [class="steam_app.*"] fullscreen enable
      for_window [class="steam_app*"] inhibit_idle focus
      # FH5: move the black window off screen
      # FH5: keep the one with the game
      assign [class="steam_app_1551360"] 2
      assign [title="Forza Horizon 5"] 1
      for_window [class="steam_app_1551360"] move window to workspace number 2
      for_window [title="Forza Horizon 5"] move window to workspace number 1

      # for_window [app_id="^.*"] floating enable, border none
      # for_window [app_id="^.*"] fullscreen enable

      assign [class="Signal"] 8
      assign [app_id="Slack"] 8
      assign [title="Spotify Premium"] 8

      # https://github.com/signalapp/Signal-Desktop/issues/5719
      #for_window [app_id="signal"] floating enable
      #assign [app_id="signal*"] 6
      #exec "signal-desktop --ozone-platform=wayland"

      workspace 6
      exec "${term} --title term-journalctl -o font.size=$status_term_font_size -e journalctl -f "
      exec "corectrl"

      workspace 7
      # don't really need these any longer
      # exec "${term} --title term-amdgpu-top amdgpu_top"
      # exec "${term} --title term-htop -o font.size=$status_term_font_size -e htop"
      exec "${term} --title term-top -o font.size=$status_term_font_size -e btop"
      exec 'resources'

      workspace 8
      exec dropbox
      exec spotify

      workspace 4
      exec qpwgraph -stylesheet ~/.config/dotfiles/config/qpwgraph/style.qss ~/graph-setup.qpwgraph

      workspace 5

      workspace 1
      exec $browser

      workspace 2
      exec emacs ~/nixos-config/configuration.nix
      # exec 'sleep 2 && swaymsg move container to workspace 2'
    '';
  };
  programs.t-firefox = {
    enable = true;
    package = pkgs.firefox-bin;
    #package = pkgs.firefox-devedition-bin;
  };

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    resources

    # TODO configure CONFIG_LATENCYTOP?
    latencytop

    # tools
    killall

    # images
    imagemagick
    gnuplot

    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/28?page=2
    inputs.nixpkgs-wayland.packages.${system}.wayprompt

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
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg # helix native needs wine with fsync patches
    (yabridge.override {
      wine = inputs.nix-gaming.packages.${pkgs.system}.wine-tkg;
    })
    (yabridgectl.override {
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

    ".config/dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    ".config/environment.d/envvars.conf".source = dotfiles
      + "/config/environment.d/envvars.conf";
    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles
      + "/config/corectrl/corectrl.ini";
  };

  # sway extras for testing sway configuration
  # environment.etc."sway/config.d/sway_extra.conf".text = ''
  # '';

  # sops with home manager is a little different, see configuration.nix
  #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #   sops.age.keyFile = "/etc/nix-sops-secret.key";
  #   sops.secrets."smb".owner = "torgeir";

  home.stateVersion = "23.11";

}
