{ config, lib, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    profiles."torgeir" = { };
    policies = {
      ExtensionSettings = with builtins;
        let
          extension = id: uuid: {
            name = uuid;
            value = {
              install_url =
                "https://addons.mozilla.org/en-US/firefox/downloads/latest/${id}/latest.xpi";
              installation_mode = "normal_installed";
            };
          };
        in listToAttrs [
          # find it on addons.mozilla.org
          # find the id in the url https://addons.mozilla.org/en-US/firefox/addon/{id}
          # install plugin extension then find the Extension ID in about:debugging#/runtime/this-firefox.
          (extension "darkreader" "addon@darkreader.org")
          (extension "ublock-origin" "uBlock0@raymondhill.net")
          (extension "vimium-ff" "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
          (extension "1password-x-password-manager"
            "{d634138d-c276-4fc8-924b-40a0ea21d284}")
        ];
    };
  };
}
