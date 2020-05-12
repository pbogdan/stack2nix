{ pkgs ? import (import ./fetch-nixpkgs.nix) {}
, profiling ? false
}:
let
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
              src = builtins.path {
                name = "stack2nix";
                path = ./.;
                # Filter hidden dirs (.), e.g. .git and .stack-work
                # TODO Remove once https://github.com/input-output-hk/stack2nix/issues/119 is done
                filter = path: type:
                  !(pkgs.lib.hasPrefix "." (baseNameOf path))
                  && baseNameOf path != "stack.yaml";
              };
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
