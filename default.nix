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

        # https://github.com/commercialhaskell/lts-haskell/issues/149
        stack = doJailbreak super.stack;

        # needed until we upgrade to 18.09
        yaml = disableCabalFlag super.yaml "system-libyaml";

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
