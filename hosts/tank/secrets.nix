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
      acme-cloudflare = {
        file = ../../secrets/acme-cloudflare.age;
        owner = "acme";
      };
      freshrss = {
        file = ../../secrets/freshrss.age;
      };
    };
  };
}
