{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "0ef8a92523ca9d463d54bcd8d1afacd526a4b6de";
  };

  nix-home-manager = builtins.fetchGit {
    url = "https://github.com/torgeir/nix-home-manager";
    rev = "d1ce560380948c7f00ab4666e352ca445de5042c";
  };
in {

  imports = [
    ./audio-production.nix
    ./browser.nix
    ./gtk.nix
    ./fonts.nix
    ./gpg.nix
    ./gaming.nix
    ./tofi.nix
    ./file-manager.nix
    (nix-home-manager + "/modules")
  ];

  programs.t-doomemacs.enable = true;
  programs.t-nvim.enable = true;
  programs.t-terminal.alacritty.enable = true;
  programs.t-zoxide.enable = true;
  programs.t-shell-tooling.enable = true;
  programs.t-tmux.enable = true;

  # find package paths with nix-env -qaP <pkg>
  #   nix-env -qaP nodejs
  #   nix-shell -p nodejs_20 --run "node -e 'console.log(42);'"
  # the same name is used here
  home.packages = with pkgs; [

    resources

    # terminal
    delta
    difftastic
    # TODO configure CONFIG_LATENCYTOP?
    latencytop

    # emacs
    nil # nix lsp https://github.com/oxalica/nil
    # TODO torgeir trace: warning: nixfmt was renamed to nixfmt-classic. The nixfmt attribute may be used for the new RFC 166-style formatter i
    nixfmt-classic

    # tools
    killall
    # screenshots
    grim
    slurp
    sway-contrib.grimshot
    swayimg

    # images
    imagemagick
    gnuplot

    # notifications
    mako
    libnotify
    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/28?page=2
    inputs.nixpkgs-wayland.packages.${system}.wayprompt

    # sensors
    inxi
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

    ".config/sway".source = dotfiles + "/config/sway";
    ".config/xkb".source = dotfiles + "/config/xkb";
    ".config/environment.d/envvars.conf".source = dotfiles
      + "/config/environment.d/envvars.conf";
    ".config/mako".source = dotfiles + "/config/mako";
    ".config/dunst".source = dotfiles + "/config/dunst";
    ".config/i3status-rust".source = dotfiles + "/config/i3status-rust";
    ".config/MangoHud".source = dotfiles + "/config/MangoHud";
    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles
      + "/config/corectrl/corectrl.ini";

    ".p10k.zsh".source = dotfiles + "/p10k.zsh";
    ".gitconfig".source = dotfiles + "/gitconfig";

    ".zsh".source = dotfiles + "/zsh/";
    ".zshrc".source = dotfiles + "/zshrc";
    ".zprofile".source = dotfiles + "/profile";
    ".inputrc".source = dotfiles + "/inputrc";
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
