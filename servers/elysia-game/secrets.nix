let
  laptopKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA";
  pcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ";
  foksikKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvj4GQR/TM/i1yZ3j8TTSJXZfOjOMY0zhAWen40+YPE foksik@nixos";
  serverKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJ8ILJ4dmKPdvsk/b0daqYdGTrcCxgHoF57PlkhcRqf root@nixos";
  allKeys = [laptopKey pcKey serverKey];
in {
  "secrets/resourcepack_namespace.age".publicKeys = allKeys;
}
