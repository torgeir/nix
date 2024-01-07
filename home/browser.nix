{ config, lib, pkgs, ... }:

let extensions = (pkgs.callPackage ./firefox-extensions.nix { });
in {
  programs.firefox = {
    enable = true;
    profiles.torgeir = {
      id = 0;
      settings = {
        # enable userChrome
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
      # https://github.com/piroor/treestyletab/wiki/Code-snippets-for-custom-style-rules#for-userchromecss
      userChrome = ''
        /* remove tabs toolbar */
        #TabsToolbar    {visibility: collapse !important;}
        /* remove tree style tabs heading a */
        #sidebar-header {visibility: collapse !important;}
      '';
      extensions = [
        extensions.darkreader
        extensions.vimium-ff
        extensions.ublock-origin
        extensions.multi-account-containers
        extensions.firefox-color
        extensions.onepassword-x-password-manager
        extensions.tree-style-tab
      ];
    };
    policies = {
      Preferences = let
        locked-false = {
          Value = false;
          Status = "locked";
        };
      in {
        # prevent cpu intensive defaults interfering with realtime audio
        "reader.parse-on-load.enabled" = locked-false;
        "media.webspeech.synth.enabled" = locked-false;
      };
    };
  };
}
