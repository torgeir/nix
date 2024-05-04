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

        # disable autoplay
        "media.autoplay.default" = 0;
        "media.autoplay.enabled" = false;

        # show full urls
        "browser.urlbar.trimURLs" = false;
        "browser.aboutConfig.showWarning" = false;

        # no pocket
        "extensions.pocket.enabled" = false;
      };
      # https://github.com/piroor/treestyletab/wiki/Code-snippets-for-custom-style-rules#for-userchromecss
      userChrome = ''
        moz-input-box,
        #urlbar-input-container {
          font-size: 1rem;
        }
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
      #https://github.com/montchr/dotfield/blob/78de8ff316ccb2d34fd98cd9bfd3bfb5ad775b0e/home/profiles/firefox/search/default.nix
      search.force = true;
      search.default = "DuckDuckGo";
      search.engines = let
        engine = alias: template: {
          definedAliases = [ "@${alias}" ];
          urls = [{ inherit template; }];
        };
      in {
        "Github Code" = engine "github-code"
          "https://github.com/search?q={searchTerms}&type=code";
        "Npm" = engine "npm" "https://www.npmjs.com/search?q={searchTerms}";
        "DuckDuckGo" =
          engine "duckduckgo" "https://duckduckgo.com/?q={searchTerms}";
        "Google" =
          engine "google" "https://www.google.com/search?q={searchTerms}";
        "Nixpkgs" = engine "nixpkgs"
          "https://search.nixos.org/packages?type=packages&query={searchTerms}";
        "Nixpkgs Unstable" = engine "nixpkgs-unstable"
          "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
        "Nixfns" = engine "nixfns" "https://noogle.dev/q?term={searchTerms}";
      };
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
