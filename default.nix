{ pkgs ? import (import ./fetch-nixpkgs.nix) {}
, profiling ? false
}:
let
  inherit (pkgs)
    nix-gitignore
  ;
  inherit (pkgs.lib)
    optionalAttrs
    ;
  inherit (pkgs.haskell.lib)
    disableCabalFlag
    doJailbreak
    justStaticExecutables
    overrideCabal
    ;
in
(
  (import ./stack2nix.nix { inherit pkgs; }).override {
    overrides = self: super: (
      {

        # TODO: separate out output
        stack2nix = justStaticExecutables (
          overrideCabal super.stack2nix (
            old: {
              src = nix-gitignore.gitignoreSource [] ./.;
            }
          )
        );

        # https://github.com/NixOS/cabal2nix/issues/146
        hinotify = if pkgs.stdenv.isDarwin then self.hfsevents else super.hinotify;
      } // optionalAttrs (!profiling) {
        mkDerivation = args: super.mkDerivation (
          args // {
            enableLibraryProfiling = false;
          }
        );
      }
    );
  }
).stack2nix
