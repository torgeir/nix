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

  # immich
  # nix run github:ryantm/agenix -- -e immich-db-password.age
  "immich-db-password.age".publicKeys = hosts;

  # CLOUDFLARE_DNS_API_TOKEN=<token>
  # nix run github:ryantm/agenix -- -e acme-cloudflare.age
  "acme-cloudflare.age".publicKeys = hosts;

  # nix run github:ryantm/agenix -- -e freshrss.age
  "freshrss.age".publicKeys = hosts;
}
