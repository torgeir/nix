{
  age = {
    secrets = {
      smb-maja-password = {
        file = ../../secrets/smb-maja-password.age;
      };
      smb-torgeir-password = {
        file = ../../secrets/smb-torgeir-password.age;
      };
      secret1 = {
        file = ../../secrets/secret1.age;
        # group = "..";
        # owner = "..";
        # mode "0440";
        # path = "/home/torgeir/.secret1"
      };

      immich-db-password = {
        file = ../../secrets/immich-db-password.age;
      };
      immich-postgres = {
        file = ../../secrets/immich-postgres.age;
      };
      acme-cloudflare = {
        file = ../../secrets/tank-acme-cf.age;
        owner = "acme";
      };
      freshrss = {
        file = ../../secrets/freshrss.age;
      };
      wallabag-env = {
        file = ../../secrets/wallabag-env.age;
      };
      wallabag-postgres = {
        file = ../../secrets/wallabag-postgres.age;
      };
      scrobble = {
        file = ../../secrets/scrobble.age;
      };
      webdav = {
        file = ../../secrets/webdav-htpasswd.age;
        owner = "wwwrun"; # apache user
      };
    };
  };
}
