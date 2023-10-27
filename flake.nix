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


        #############################################
        #
        # running cabal2nix manually gives us:
        #
        # ------------------------------------------
        # { mkDerivation, aeson, alex, ansi-terminal, array, async, base
        # , binary, blaze-html, boxes, bytestring, Cabal, case-insensitive
        # , containers, data-hash, deepseq, directory, dlist, edit-distance
        # , emacs, equivalence, exceptions, filepath, ghc-compact, gitrev
        # , happy, hashable, haskeline, lib, monad-control, mtl, murmur-hash
        # , parallel, peano, pretty, process, regex-tdfa, split, stm
        # , STMonadTrans, strict, text, time, time-compat, transformers
        # , unordered-containers, uri-encode, vector, vector-hashtables, zlib
        # }:
        # mkDerivation {
        #   pname = "Agda";
        #   version = "2.6.5";
        #   src = ./.;
        #   isLibrary = true;
        #   isExecutable = true;
        #   enableSeparateDataOutput = true;
        #   setupHaskellDepends = [ base Cabal directory filepath process ];
        #   libraryHaskellDepends = [
        #     aeson ansi-terminal array async base binary blaze-html boxes
        #     bytestring case-insensitive containers data-hash deepseq directory
        #     dlist edit-distance equivalence exceptions filepath ghc-compact
        #     gitrev hashable haskeline monad-control mtl murmur-hash parallel
        #     peano pretty process regex-tdfa split stm STMonadTrans strict text
        #     time time-compat transformers unordered-containers uri-encode
        #     vector vector-hashtables zlib
        #   ];
        #   libraryToolDepends = [ alex happy ];
        #   executableHaskellDepends = [ base directory filepath process ];
        #   executableToolDepends = [ emacs ];
        #   homepage = "https://wiki.portal.chalmers.se/agda/";
        #   description = "A dependently typed functional programming language and proof assistant";
        #   license = lib.licenses.mit;
        # }
        # ------------------------------------------
        #############################################




        # documentation on the available options is here:
        #   https://github.com/NixOS/nixpkgs/blob/643419f02b5762a811c9da82011380390e18ae94/doc/languages-frameworks/haskell.section.md
        generatedPackage2 = pkgs.haskell.lib.overrideCabal generatedPackage (drv: {
          doHoogle = false;
          doHaddock = false;
          doCheck = false;
          isLibrary = false;
          enableSharedLibraries = false;
          enableStaticLibraries = false;
          enableLibraryProfiling = false;
          enableExecutableProfiling = false;

          enableSeparateDataOutput = false;


          # the cabal2nix tool has some hardcoded behaviour
          # if the cabal package happens to be called Agda:
          #   https://github.com/NixOS/cabal2nix/blob/0365d9b77086d26ca5197fb48019cedbb0dce5d2/cabal2nix/src/Distribution/Nixpkgs/Haskell/FromCabal/PostProcess.hs#L77
          #
          # We revert those here, because a clean build is enough,
          # and we don't want the emacs-mode and neither emacs itself.
          # postInstall = "";
          executableToolDepends = [ ];
          postInstall =
          ''
            rm -r $out/lib
          '';

            # $out/bin/agda -c --no-main $(find $data/share -name Primitive.agda)
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
