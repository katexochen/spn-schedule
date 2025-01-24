{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          spn = pkgs.writeShellApplication {
            name = "spn";
            runtimeInputs = with pkgs; [
              yq-go
              curl
            ];
            text = builtins.readFile ./spn.sh;
          };
        }
      );
    };
}
