# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

{
  description = "My haskell application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/038b2922be3fc096e1d456f93f7d0f4090628729";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        # DON'T FORGET TO PUT YOUR PACKAGE NAME HERE, REMOVING `throw`
        packageName = "agda";

        generatedPackage =
        (
          pkgs.haskellPackages.callCabal2nix "Agda-determi-io-build" self rec
          {
            # Dependency overrides go here
          }
        );

        generatedPackage2 = pkgs.haskell.lib.overrideCabal generatedPackage (drv: {
          doHoogle = false;
          doHaddock = false;
          doCheck = false;
          # isLibrary = false;
          # enableSharedLibraries = false;
          enableStaticLibraries = false;
          enableLibraryProfiling = false;
          enableExecutableProfiling = false;
          # postInstall = "";
          # ''
          #   $out/bin/agda -c --no-main $(find $data/share -name Primitive.agda)
          # '';
        });

        # xxxx = throw generatedPackage.testHaskellDepends;

      in {
        packages.${packageName} = generatedPackage2;

        packages.default = self.packages.${system}.${packageName};
        defaultPackage = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.haskellPackages.haskell-language-server # you must build it with your ghc to work
            ghcid
            cabal-install
          ];
          inputsFrom = map (__getAttr "env") (__attrValues self.packages.${system});
        };
        devShell = self.devShells.${system}.default;
      });
}
