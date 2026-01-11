{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  dotfiles = inputs.dotfiles;
  pinentry = pkgs.writeShellScriptBin "gpg-1p-pinentry" ''
    exec 3>&1 4>&2
    echo "OK Pleased to meet you"
    while IFS= read -r line; do
      case "$line" in
        "GETPIN")
          if PASSPHRASE=$(/run/wrappers/bin/op item get keybase.io --format json | /etc/profiles/per-user/torgeir/bin/jq  -j '.fields[] | select(.id == "password") | .value' 2>/dev/null); then
            echo "D $PASSPHRASE"
            echo "OK"
          else
            echo "ERR 83886179 Failed to retrieve passphrase <Pinentry>"
          fi
          ;;
        "PKDECRYPT")
          echo "OK"
          ;;
        "BYE")
          echo "OK closing connection"
          exit 0
          ;;
        *)
          echo "OK"
          ;;
      esac
    done
  '';
in
{

  #https://github.com/tejing1/nixos-config/blob/master/homeConfigurations/tejing/encryption.nix
  # https://freerangebits.com/posts/2023/12/gnupg-broke-emacs/
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg24;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    maxCacheTtl = 28800;
    defaultCacheTtl = 28800;
    maxCacheTtlSsh = 28800;
    defaultCacheTtlSsh = 28800;
    extraConfig = ''
      pinentry-program "${lib.getExe pinentry}"
    '';
  };

}
