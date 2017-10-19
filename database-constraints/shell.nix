{ nixpkgs ? import <nixpkgs> {}, compiler ? "default" }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, base, hedgehog, stdenv }:
      mkDerivation {
        pname = "database-constraints";
        version = "0.1.0.0";
        src = ./.;
        isLibrary = false;
        isExecutable = false;
        testHaskellDepends = [ base hedgehog ];
        license = stdenv.lib.licenses.bsd3;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  drv = haskellPackages.callPackage f {};

in

  if pkgs.lib.inNixShell then drv.env else drv
