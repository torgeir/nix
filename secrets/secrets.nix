let
  tank = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIEQt9BNUV7U13ekLERFnHvf2FIKWx8zVKq8TP28a/H root@tank";
  torgeir = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITJ5UIW0lXbeFfyOrdCXAfBtZsq/NycSzIADDZDi3TL";
in
{
  # nix run github:ryantm/agenix -- -e secret1.age
  # nix run github:ryantm/agenix -- --rekey -e secret1.age
  # to rekey you must have private key to decrypt it first
  "secret1.age".publicKeys = [
    tank
    torgeir
  ];
}
