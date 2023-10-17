{ config, lib, pkgs, inputs, ... }:

let
  dotfiles = builtins.fetchGit {
    url = "https://github.com/torgeir/dotfiles";
    rev = "65c096f514c9366cd6d3763d5305099fc19316ad";
  };
  dotemacs = builtins.fetchGit {
    url = "https://github.com/torgeir/.emacs.d";
    rev = "5bfeecdd89d256ae1ce1e2885bf136a29d65e19f";
  };
in
{
  fonts.fontconfig.enable = true;

  programs = {

    home-manager.enable = true;

    autojump = {
      enable = true;
    };

    # https://github.com/stefanDeveloper/nixos-lenovo-config/blob/master/modules/apps/editor/vim.nix
    neovim = {
      enable = true;
      vimAlias = true;
      vimdiffAlias = true;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "arc-theme";
      package = pkgs.arc-theme;
    };
    iconTheme = {
      name = "Arc";
      package = pkgs.arc-icon-theme;
    };
    cursorTheme = {
      name = "Arc";
      package = pkgs.arc-icon-theme;
    };
  };

  #https://github.com/tejing1/nixos-config/blob/master/homeConfigurations/tejing/encryption.nix
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    maxCacheTtl = 14400;
    defaultCacheTtl = 14400;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };

  # doom emacs
  # inspiration https://discourse.nixos.org/t/advice-needed-installing-doom-emacs/8806/7
  #
  # https://nixos.wiki/wiki/Emacs
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/emacs/default.nix
  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-gtk3;
    extraPackages = epkgs: [ epkgs.vterm ];
  };

  xdg.enable = true;
  home = {
    # put doom on path
    sessionPath = [ "${config.xdg.configHome}/emacs/bin" ];
    sessionVariables = {
      # where doom is
      DOOMDIR = "${config.xdg.configHome}/doom.d";
      # where doom writes cache etc
      DOOMLOCALDIR = "${config.xdg.configHome}/doom-local";
      # where doom writes one more file
      DOOMPROFILELOADFILE= "${config.xdg.configHome}/doom-local/cache/profile-load.el";
    };
  };
  xdg.configFile = {
    "doom.d".source = dotemacs;
    "emacs" = {
      source = builtins.fetchGit {
        url = "https://github.com/hlissner/doom-emacs";
        rev = "986398504d09e585c7d1a8d73a6394024fe6f164";
      };
      # rev bumps will make doom sync run
      onChange = "${pkgs.writeShellScript "doom-change" ''
        # where your .doom.d files go
        export DOOMDIR="${config.home.sessionVariables.DOOMDIR}"

        # where doom will write to
        export DOOMLOCALDIR="${config.home.sessionVariables.DOOMLOCALDIR}"

        # https://github.com/doomemacs/doomemacs/issues/6794
        export DOOMPROFILELOADFILE="${config.home.sessionVariables.DOOMPROFILELOADFILE}"

        # cannot find git, cannot find emacs
        export PATH="$PATH:/run/current-system/sw/bin"
        export PATH="$PATH:/etc/profiles/per-user/torgeir/bin"

        if command -v emacs; then

          # not already installed
          if [ ! -d "$DOOMLOCALDIR" ]; then

            # having the env generated also prevents doom install from asking y/n on stdin,
            # also bring ssh socket
            ${config.xdg.configHome}/emacs/bin/doom env -a ^SSH_

            echo "doom-change :: Doom not installed: run doom install. ::"

            # this times out with home manager
            # ${config.xdg.configHome}/emacs/bin/doom install

          else

            echo "doom-change :: Doom already present: upgrade packages with doom sync -u ::"
            ${config.xdg.configHome}/emacs/bin/doom sync

            # this times out with home manager
            # ${config.xdg.configHome}/emacs/bin/doom sync -u

          fi

        else
          echo "doom-change :: No emacs on path. ::"
        fi

      ''}";
    };

    "foot/foot.ini".text = ''
      font=JetBrainsMono Nerd Font:style=Regular:size=12
    '';
  };


  # TODO inspiration for more
  # - https://github.com/hlissner/dotfiles/
  # - https://github.com/colemickens/nixcfg/
  # - https://github.com/nix-community/home-manager/
  # - https://github.com/nix-community/nixpkgs-wayland
  # - https://github.com/NixOS/nixpkgs/

  home.packages = with pkgs; [
    # terminal
    alacritty
    eza

    # env
    direnv
    #nodejs

    # tools
    killall
    jq
    (ripgrep.override {withPCRE2 = true;})

    # images
    imagemagick

    # notifications
    paper-icon-theme
    mako
    libnotify
    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/28?page=2
    inputs.nixpkgs-wayland.packages.${system}.wayprompt

    # sensors
    btop
    psensor
    i3status-rust

    #https://nixos.wiki/wiki/Samba

    # apps
    mpv
    ncdu
    signal-desktop
    spotify
    playerctl
    dropbox

    # sound
    pavucontrol
    qpwgraph

    # internet
    brave

    # fonts
    (pkgs.nerdfonts.override {
      fonts = [
        "JetBrainsMono"
        "Iosevka"
      ];
    })
  ];

  # this puts files in the needed locations, but does however not make them
  # editable allows interop with torgeir/dotfiles.git without moving all this
  # configuration to .nix files
  home.file = {
    "dotfiles".source = dotfiles;

    "bg.jpg".source = dotfiles + "/bg.jpg";

    ".config/alacritty/alacritty.yml".source = dotfiles + "/config/alacritty/alacritty.yml";
    ".config/sway".source = dotfiles + "/config/sway";
    ".config/xkb".source = dotfiles + "/config/xkb";
    ".config/environment.d/envvars.conf".source = dotfiles + "/config/environment.d/envvars.conf";
    ".config/mako".source = dotfiles + "/config/mako";
    ".config/dunst".source = dotfiles + "/config/dunst";
    ".config/i3status-rust".source = dotfiles + "/config/i3status-rust";

    ".config/corectrl/profiles".source = dotfiles + "/config/corectrl/profiles";
    ".config/corectrl/corectrl.ini".source = dotfiles + "/config/corectrl/corectrl.ini";

    ".config/pipewire".source = dotfiles + "/config/pipewire";
    ".config/wireplumber".source = dotfiles + "/config/wireplumber";

    ".p10k.zsh".source = dotfiles + "/p10k.zsh";
    ".gitconfig".source = dotfiles + "/gitconfig";

    ".zsh".source = dotfiles + "/zsh/";
    ".zshrc".source = dotfiles + "/zshrc";
    ".zprofile".source = dotfiles + "/profile";
    ".inputrc".source = dotfiles + "/inputrc";
  };

  home.stateVersion = "23.11";

}
