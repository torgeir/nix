{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "64b2189f22a4d380bf9b890977f2b3bfff32ffb4";
  };
in {

  imports = [
    ./audio-production.nix
    ./autojump.nix
    ./browser.nix
    ./gtk.nix
    ./fonts.nix
    ./gpg.nix
    ./terminal
    ./editors
    ./file-manager.nix
  ];

  # let home manager install and manage itself
  programs.home-manager.enable = true;

  # inspiration for more
  # - https://github.com/panchoh/nixos
  # - https://github.com/hlissner/dotfiles/
  # - https://github.com/colemickens/nixcfg/
  # - https://github.com/nix-community/home-manager/
  # - https://github.com/nix-community/nixpkgs-wayland
  # - https://github.com/NixOS/nixpkgs/
  #
  # - https://github.com/Horus645/swww
  # - https://github.com/redyf/nixdots

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    # terminal
    alacritty
    eza
    htop
    # TODO configure CONFIG_LATENCYTOP?
    latencytop

    # emacs
    nil # nix lsp https://github.com/oxalica/nil
    nixfmt

    # env
    direnv
    #nodejs

    # tools
    killall
    jq
    (ripgrep.override { withPCRE2 = true; })
    # screenshots
    grim
    slurp
    sway-contrib.grimshot
    swayimg

    # images
    imagemagick

    # notifications
    mako
    libnotify
    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/28?page=2
    inputs.nixpkgs-wayland.packages.${system}.wayprompt

    # sensors
    inxi
    btop
    psensor
    i3status-rust

    #https://nixos.wiki/wiki/Samba

    # formats
    flac

    # apps
    mpv
    #mpc-cli
    ncmpcpp # mpd music player

    ncdu
    signal-desktop
    spotify
    slack
    playerctl
    dropbox

    # sound
    pavucontrol
    qpwgraph

    # unused, pipewire handles this
    # https://nixos.wiki/wiki/JACK
    # libjack2
    # jack2
    qjackctl

    # sudo -EH rpi-imager
    rpi-imager

    # wallpapers
    # https://github.com/natpen/awesome-wayland#wallpaper

    # fonts
    (pkgs.nerdfonts.override {
      fonts = [ "JetBrainsMono" "Iosevka" "IosevkaTerm" ];
    })

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
    "dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    # ".config/sway".source = dotfiles + "/config/sway";
    ".config/sway/config".text = ''
      # Inspiration
      # - https://github.com/rbnis/dotfiles/blob/master/.config/sway/config
      #
      # Focus a window
      #   swaymsg "[class=Emacs] focus"
      # More
      #   man 5 sway-input

      # Super. Use Mod1 for Alt.
      set $mod Mod4

      # Home row
      set $left h
      set $down j
      set $up k
      set $right l

      set $term foot
      set $browser firefox
      set $filemanager thunar

      # hide mouse
      #seat * hide_cursor 8000
      seat * hide_cursor when-typing enable

      ## TODO
      # xwayland disable

      # Your preferred application launcher
      # Note: pass the final command to swaymsg so that the resulting window can be opened
      # on the original workspace that the command was run on.
      set $menu dmenu-wl_run -i

      # Inputs (swaymsg -t get_inputs)
      input type:keyboard {
        xkb_file "~/.config/xkb/symbols/custom"
      }

      # Outputs (swaymsg -t get_outputs)
      output * {
        resolution 2560x1440
      }

      output DP-2 {
        bg ~/bg.jpg fill
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
        bg ~/bg.jpg fill
        transform 270
        mode 2560x1440@59.951Hz
      }
      workspace 1 output DP-2
      workspace 2 output DP-2
      workspace 3 output DP-2
      workspace 4 output DP-2
      workspace  5 output DP-1
      workspace  6 output DP-1
      workspace  7 output DP-1
      workspace  8 output DP-1
      workspace  9 output DP-1
      workspace 10 output DP-1

      # Opacity
      set $opacity 0.97
      for_window [class=".*"] opacity $opacity
      for_window [app_id=".*"] opacity $opacity

      # Gaps
      smart_gaps off
      # on new workspaces
      gaps inner 10
      gaps outer 0
      # adjust runtime
      #swaymsg gaps inner all set 10
      #swaymsg gaps outer all set 0

      # Borders
      default_border pixel 5
      default_floating_border normal
      client.focused #00aaff #ff00aa #00ffaa
      #hide_edge_borders smart

      # Idle configuration
      #   Lock and later turn off display. Turn screen on resume. Lock before sleep.
      exec swayidle -w \
        timeout 300 'swaylock -f -c 000000' \
        timeout 350 'swaymsg "output * dpms off"' \
        resume 'swaymsg "output * dpms on"' \
        before-sleep 'swaylock -f -c 000000'

      ### Bindings
      bindsym $mod+Return exec emacsclient --eval '\
        (if (frame-focus-state)\
        (with-current-buffer (buffer-name (window-buffer (frame-selected-window)))\
        (t/vterm-here))\
        (with-selected-frame (make-frame)\
        (let ((default-directory (t/read-file (t/user-file ".cur"))))\
        (+vterm/here t))))'
      bindsym $mod+Shift+Return exec $browser
      bindsym $mod+Ctrl+Return exec $term
      bindsym $mod+n exec $filemanager

      # Kill
      bindsym $mod+Shift+q kill

      # Launcher
      bindsym $mod+Space exec $menu

      # Mouse move window
      floating_modifier $mod normal

      # Reload the configuration file
      bindsym $mod+Ctrl+c reload

      # Exit
      bindsym $mod+Ctrl+e exec 'swaymsg exit'
      bindsym $mod+Ctrl+s exec 'systemctl suspend'
      bindsym $mod+Ctrl+r exec 'systemctl reboot'
      bindsym $mod+Ctrl+p exec 'systemctl poweroff'
      bindsym $mod+Ctrl+l exec 'swaylock -f -c 000000'

      # Media buttons
      bindsym XF86AudioPlay exec playerctl play-pause
      bindsym XF86AudioNext exec playerctl next
      bindsym XF86AudioPrev exec playerctl previous

      ### Move around
      # Move focus
      bindsym Mod1+$left focus left
      bindsym Mod1+$down focus down
      bindsym Mod1+$up focus up
      bindsym Mod1+$right focus right
      # Ditto, super
      bindsym $mod+Left focus left
      bindsym $mod+Down focus down
      bindsym $mod+Up focus up
      bindsym $mod+Right focus right

      # Move window
      bindsym Mod1+Shift+$left move left
      bindsym Mod1+Shift+$down move down
      bindsym Mod1+Shift+$up move up
      bindsym Mod1+Shift+$right move right
      # Ditto, super
      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right

      ### Workspaces:
      # Switch
      bindsym $mod+0 workspace number 10
      bindsym $mod+1 workspace number 1
      bindsym $mod+2 workspace number 2
      bindsym $mod+3 workspace number 3
      bindsym $mod+4 workspace number 4
      bindsym $mod+5 workspace number 5
      bindsym $mod+6 workspace number 6
      bindsym $mod+7 workspace number 7
      bindsym $mod+8 workspace number 8
      bindsym $mod+9 workspace number 9
      # Containers
      bindsym $mod+Shift+1 move container to workspace number 1; workspace 1
      bindsym $mod+Shift+2 move container to workspace number 2; workspace 2
      bindsym $mod+Shift+3 move container to workspace number 3; workspace 3
      bindsym $mod+Shift+4 move container to workspace number 4; workspace 4
      bindsym $mod+Shift+5 move container to workspace number 5; workspace 5
      bindsym $mod+Shift+6 move container to workspace number 6; workspace 6
      bindsym $mod+Shift+7 move container to workspace number 7; workspace 7
      bindsym $mod+Shift+8 move container to workspace number 8; workspace 8
      bindsym $mod+Shift+9 move container to workspace number 9; workspace 9
      bindsym $mod+Shift+0 move container to workspace number 10; workspace 10
      bindsym Mod1+Shift+1 move container to workspace number 1; workspace 1
      bindsym Mod1+Shift+2 move container to workspace number 2; workspace 2
      bindsym Mod1+Shift+3 move container to workspace number 3; workspace 3
      bindsym Mod1+Shift+4 move container to workspace number 4; workspace 4
      bindsym Mod1+Shift+5 move container to workspace number 5; workspace 5
      bindsym Mod1+Shift+6 move container to workspace number 6; workspace 6
      bindsym Mod1+Shift+7 move container to workspace number 7; workspace 7
      bindsym Mod1+Shift+8 move container to workspace number 8; workspace 8
      bindsym Mod1+Shift+9 move container to workspace number 9; workspace 9
      bindsym Mod1+Shift+0 move container to workspace number 10; workspace 10

      ### Layout stuff
      bindsym Mod1+Shift+s layout toggle split #tabbed stacking
      bindsym Mod1+Shift+g splith
      bindsym Mod1+Shift+v splitv

      # Maximize
      bindsym Mod1+Shift+m fullscreen

      # Toggle the current focus between tiling and floating mode
      bindsym $mod+Shift+f floating toggle

      # Swap between tiling window and the floating window
      bindsym $mod+Ctrl+f focus mode_toggle

      # Move focus to the parent container
      bindsym Mod1+Shift+p focus parent

      # Scratch
      bindsym $mod+Ctrl+m move scratchpad
      bindsym $mod+Ctrl+a scratchpad show

      # Screenshots
      set $mode_screenshot "Screenshot: (s)election|(d)isplay|(w)indow|(p)ixel value"
      mode $mode_screenshot {
        bindsym s exec ~/dotfiles/config/sway/screenshot.sh s; mode "default"
        bindsym d exec ~/dotfiles/config/sway/screenshot.sh d; mode "default"
        bindsym w exec ~/dotfiles/config/sway/screenshot.sh w; mode "default"
        bindsym p exec ~/dotfiles/config/sway/screenshot.sh p; mode "default"
        bindsym Escape mode "default"

      }
      bindsym $mod+ctrl+Mod1+s mode $mode_screenshot

      bindsym Ctrl+$mod+Left resize shrink width 100px
      bindsym Ctrl+$mod+Down resize grow height 100px
      bindsym Ctrl+$mod+Up resize shrink height 100px
      bindsym Ctrl+$mod+Right resize grow width 100px

      ### Status Bar (man 5 sway-bar)
      bar {
        position bottom
        font pango:DejaVu Sans Mono, FontAwesome 10
        status_command i3status-rs ~/.config/i3status-rust/config.toml
        colors {
          separator #666666
          background #222222
          statusline #dddddd
          focused_workspace #0088CC #0088CC #ffffff
          active_workspace #333333 #333333 #ffffff
          inactive_workspace #333333 #333333 #888888
          urgent_workspace #2f343a #900000 #ffffff
        }
      }

      # Sticky
      bindsym $mod+p sticky toggle;exec notify-send 'sticky'

      # Window classes (swaymsg -t get_tree | rg class)
      # Lookup windows: https://gist.github.com/dshoreman/278091a17c08e30c46c7e7988b7c2f7d
      # What goes where

      for_window [title="Picture-in-Picture"] floating enable sticky enable border none

      assign [class="Brave-browser"] 1
      for_window [class="Brave-browser" title="Picture in picture"] floating enable sticky enable border none

      # assign [class="Emacs"] 2

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
      for_window [class="REAPER" title="FX"] floating enable
      for_window [class="REAPER" title="^LV2.*"] floating enable
      for_window [class="REAPER" title=".*JS.*"] floating enable
      for_window [class="REAPER" title="^VST.*"] floating enable

      assign [title="^Psensor.*"] 5
      for_window [title="^Psensor.*"] resize set height 512px
      for_window [title="^alacritty-journalctl"] resize set height 300px

      for_window [title="^alacritty-amdgpu-top"] resize set height 1450px

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

      assign [class="Slack"] 7
      assign [class="Signal"] 7
      assign [class="Spotify"] 8

      exec dropbox

      exec "signal-desktop"

      exec 'alacritty --title alacritty-btop -e btop'
      exec 'env -u WAYLAND_DISPLAY psensor'
      exec 'alacritty --title alacritty-journalctl -e journalctl -f'

      workspace 6
      exec 'alacritty --title alacritty-amdgpu-top -e amdgpu_top'
      exec corectrl

      workspace 4
      exec qpwgraph -stylesheet ~/dotfiles/config/qpwgraph/style.qss ~/graph-setup.qpwgraph

      # set screen 2 workspace
      workspace 5
      # set screen 1 workspace
      workspace 1
      exec $browser

      workspace 2
      exec emacs ~/nixos-config/configuration.nix
      # exec 'sleep 2 && swaymsg move container to workspace 2'

      include /etc/sway/config.d/*
    '';
    ".config/xkb".source = dotfiles + "/config/xkb";
    ".config/environment.d/envvars.conf".source = dotfiles
      + "/config/environment.d/envvars.conf";
    ".config/mako".source = dotfiles + "/config/mako";
    ".config/dunst".source = dotfiles + "/config/dunst";
    ".config/i3status-rust".source = dotfiles + "/config/i3status-rust";
    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles
      + "/config/corectrl/corectrl.ini";

    # https://linuxmusicians.com/viewtopic.php?t=26271
    # pw-metadata -n settings 0 clock.force-quantum 48
    ".config/pipewire/jack.conf.d/override.conf".text = ''
      jack.properties = {
        node.force-quantum = 384
        #node.force-quantum = 144
        #node.force-quantum = 48
      }
    '';

    ".p10k.zsh".source = dotfiles + "/p10k.zsh";
    ".gitconfig".source = dotfiles + "/gitconfig";

    ".zsh".source = dotfiles + "/zsh/";
    ".zshrc".source = dotfiles + "/zshrc";
    ".zprofile".source = dotfiles + "/profile";
    ".inputrc".source = dotfiles + "/inputrc";
  };

  # sops with home manager is a little different, see configuration.nix
  #   imports = [ inputs.sops-nix.homeManagerModules.sops ];
  #   sops.age.keyFile = "/etc/nix-sops-secret.key";
  #   sops.secrets."smb".owner = "torgeir";

  home.stateVersion = "23.11";

}
