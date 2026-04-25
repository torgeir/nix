let
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIEQt9BNUV7U13ekLERFnHvf2FIKWx8zVKq8TP28a/H root@tank";
  torgeir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL";
  hosts = [
    tank
    torgeir
  ];
in
{
  # nix run github:ryantm/agenix -- -e secret1.age
  # nix run github:ryantm/agenix -- --rekey -e secret1.age
  # to rekey you must have private key to decrypt it first
  "secret1.age".publicKeys = hosts;

  # nix run github:ryantm/agenix -- -e smb-maja-password.age
  "smb-maja-password.age".publicKeys = hosts;
  # nix run github:ryantm/agenix -- -e smb-torgeir-password.age
  "smb-torgeir-password.age".publicKeys = hosts;
  #nix run github:ryantm/agenix -- -e smb-torgeir-credentials.age
  #     username: <username>
  #     password: <password>
  "smb-torgeir-credentials.age".publicKeys = hosts;

  # immich-app/immich-server
  # nix run github:ryantm/agenix -- -e immich-db-password.age
  "immich-db-password.age".publicKeys = hosts;
  # immich-app/postgres
  # nix run github:ryantm/agenix -- -e immich-postgres.age
  "immich-postgres.age".publicKeys = hosts;

  # CLOUDFLARE_DNS_API_TOKEN=<token>
  # nix run github:ryantm/agenix -- -e tank-acme-cf.age
  "tank-acme-cf.age".publicKeys = hosts;

  # nix run github:ryantm/agenix -- -e torgnix-acme-cf.age
  "torgnix-acme-cf.age".publicKeys = [ torgeir ];

  # nix run github:ryantm/agenix -- -e freshrss.age
  "freshrss.age".publicKeys = hosts;

  # wallabag app env (SYMFONY__ENV__DATABASE_PASSWORD, SYMFONY__ENV__SECRET)
  # nix run github:ryantm/agenix -- -e wallabag-env.age
  "wallabag-env.age".publicKeys = hosts;
  # wallabag postgres
  # nix run github:ryantm/agenix -- -e wallabag-postgres.age
  "wallabag-postgres.age".publicKeys = hosts;

  # nix run github:ryantm/agenix -- -e scrobble.age
  "scrobble.age".publicKeys = hosts;

  # nix-shell -p apacheHttpd --run 'htpasswd -c webdav-htpasswd <user>'
  # cat webdav-htpasswd | wl-copy; rm webdav-htpasswd;
  # paste it here:
  # nix run github:ryantm/agenix -- -e webdav-htpasswd.age
  "webdav-htpasswd.age".publicKeys = hosts;

}
