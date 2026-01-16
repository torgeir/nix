{
  age = {
    # my own key copied here, this is needed or openssh is needed
    # sudo chmod 600 /etc/ssh/ssh_host_ed25519_key
    # sudo chown root:root /etc/ssh/ssh_host_ed25519_key
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      smb-torgeir-credentials = {
        file = ../../secrets/smb-torgeir-credentials.age;
        owner = "torgeir";
      };
    };
  };
}
