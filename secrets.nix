let
  laptopKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA";
  pcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ";
  foksikKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJvj4GQR/TM/i1yZ3j8TTSJXZfOjOMY0zhAWen40+YPE foksik@nixos";
  elysiaGame = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJ8ILJ4dmKPdvsk/b0daqYdGTrcCxgHoF57PlkhcRqf root@nixos";
in {
  "files/certs/elysiac.fun.key".publicKeys = [laptopKey pcKey foksikKey elysiaGame];
  "files/certs/elysia-game-ech_elysiac.fun.pem".publicKeys = [laptopKey pcKey foksikKey elysiaGame]; 
}
