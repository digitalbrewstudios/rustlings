{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz"; # Compatability without experimental
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          pkgs,
          system,
          lib,
          ...
        }:
        let
          cargoToml = lib.importTOML ../../Cargo.toml;
          rawRustVersion = cargoToml.workspace.package."rust-version";
          rustVersion =
            if builtins.match "^[0-9]+\\.[0-9]+$" rawRustVersion != null then
              "${rawRustVersion}.0"
            else
              rawRustVersion;
        in
        {
          # Required for rust overlay to work it's magic.
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (import inputs.rust-overlay)
            ];
          };

          devShells.default = pkgs.mkShell {
            nativeBuildInputs = [
              (pkgs.rust-bin.stable.${rustVersion}.default) # Rust toolchain, if having issues update the lock file with `nix flake update`
            ];
          };
        };
    };
}
