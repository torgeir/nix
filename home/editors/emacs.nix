{ config, lib, pkgs, ... }:

{

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
      DOOMPROFILELOADFILE =
        "${config.xdg.configHome}/doom-local/cache/profile-load.el";
    };
  };
  xdg.configFile = {
    # git clone git@github.com:torgeir/.emacs.d.git ~/.doom.d
    "doom.d".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.doom.d";
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
  };

}
