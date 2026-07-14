let
  laptopKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPngKu24f4aaEROijzY/YSpBBJsLLIfBq+0ri7HamSQA";
  pcKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII957WmPPCOJTsKjHS6dJ4OT+SObewPbOH1BK537mgsQ";
  serverKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIyheLaNW6355J67HICh3g4lGvS0qFda58rZmI5gWqNJ";
  allKeys = [laptopKey pcKey serverKey];
in {
  "secrets/resourcepack_namespace.age".publicKeys = allKeys;
}
