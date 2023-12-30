{
  description = "Small image server";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {self, nixpkgs, flake-utils}: {
    overlay = final: prev: {
      blanketcon-2023 = final.poetry2nix.mkPoetryApplication {
        projectDir = ./.;
        preferWheels = true;
      };
    };
  } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; overlays = [self.overlay]; }; in
      {
          packages.default = pkgs.blanketcon-2023;
      });
}
