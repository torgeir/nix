{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  data = "/fast/shared/apps/webdav/";
in
{
  system.activationScripts.createWebdavFolders = lib.mkAfter ''
    mkdir -p ${data}
    chown wwwrun:wwwrun ${data}
    chmod 755 ${data}
    for folder in Supernote Books; do
      mkdir -p ${data}/$folder
      chown wwwrun:wwwrun ${data}/$folder
      chmod 755 ${data}/Books
    done
    mkdir -p /var/lock/httpd
    chown wwwrun:wwwrun /var/lock/httpd
  '';

  users.users.wwwrun.extraGroups = [ "acme" ];

  services.httpd = {
    enable = true;
    adminAddr = "torgeir.thoresen@gmail.com";
    extraModules = [
      "dav"
      "dav_fs"
    ];
    virtualHosts."webdav-internal" = {
      listen = [
        {
          ip = "127.0.0.1";
          port = 8092;
          ssl = false;
        }
      ];
      documentRoot = data;
      extraConfig = ''
        DAVLockDB /var/lock/httpd/DAVLock
        DirectorySlash Off
        <Directory "${data}">
          DAV On
          AuthType Basic
          AuthName "WebDAV"
          AuthUserFile ${config.age.secrets.webdav.path}
          Require valid-user
        </Directory>
      '';
    };
  };
}
