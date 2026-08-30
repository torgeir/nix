# Rekey (re-encrypt all secrets to the publicKeys below):
#   1. op read "op://<vault>/<admin-key>/private key" > /tmp/k && chmod 600 /tmp/k
#   2. edit recipients below as needed
#   3. cd secrets && nix run github:ryantm/agenix -- --rekey -i /tmp/k
#   4. shred -u /tmp/k
# Note: decrypt with a key already a recipient (admin key); use a real file, not <(...).
# Every secret must list `admins` or you lock yourself out.
#
# Peek
# EDITOR=cat nix run github:ryantm/agenix -- \
#  -e file.age \
#  -i <(op read "op://<vault>/<entry>/<field>")

let
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIEQt9BNUV7U13ekLERFnHvf2FIKWx8zVKq8TP28a/H root@tank";
  torgeir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/yYpuSnWCBRKX/3bY1csXcNMgwVqyS5UArfBvXUkhk torgeir@torgnix";
  torgnix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJM6CNNRtA1DnAtFPLOSmKdKAE8vlFfa+QJXcfa28lwt torgeir@torgnix";
  admins = [ torgeir ];
  hosts = [
    tank
    torgnix
  ];
in
{
  #nix run github:ryantm/agenix -- -e smb-torgeir-credentials.age
  #     username: <username>
  #     password: <password>
  "smb-torgeir-credentials.age".publicKeys = admins ++ [ torgnix ];

  # nix run github:ryantm/agenix -- -e torgnix-acme-cf.age
  "torgnix-acme-cf.age".publicKeys = admins ++ [ torgnix ]; # FIXME outdated

  # nix run github:ryantm/agenix -- -e smb-maja-password.age
  "smb-maja-password.age".publicKeys = admins ++ [ tank ];
  # nix run github:ryantm/agenix -- -e smb-torgeir-password.age
  "smb-torgeir-password.age".publicKeys = admins ++ [ tank ];

  # immich-app/immich-server
  # nix run github:ryantm/agenix -- -e immich-db-password.age
  "immich-db-password.age".publicKeys = admins ++ [ tank ];
  # immich-app/postgres
  # nix run github:ryantm/agenix -- -e immich-postgres.age
  "immich-postgres.age".publicKeys = admins ++ [ tank ];

  # CLOUDFLARE_DNS_API_TOKEN=<token>
  # nix run github:ryantm/agenix -- -e tank-acme-cf.age
  "tank-acme-cf.age".publicKeys = admins ++ [ tank ]; # FIXME outdated

  # nix run github:ryantm/agenix -- -e freshrss.age
  "freshrss.age".publicKeys = admins ++ [ tank ];

  # wallabag app env (SYMFONY__ENV__DATABASE_PASSWORD, SYMFONY__ENV__SECRET)
  # nix run github:ryantm/agenix -- -e wallabag-env.age
  "wallabag-env.age".publicKeys = admins ++ [ tank ];
  # wallabag postgres
  # nix run github:ryantm/agenix -- -e wallabag-postgres.age
  "wallabag-postgres.age".publicKeys = admins ++ [ tank ];

  # nix run github:ryantm/agenix -- -e scrobble.age
  "scrobble.age".publicKeys = admins ++ [ tank ];

  # nix-shell -p apacheHttpd --run 'htpasswd -c webdav-htpasswd <user>'
  # cat webdav-htpasswd | wl-copy; rm webdav-htpasswd;
  # paste it here:
  # nix run github:ryantm/agenix -- -e webdav-htpasswd.age
  "webdav-htpasswd.age".publicKeys = admins ++ [ tank ];

}
