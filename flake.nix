{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          config,
          self',
          pkgs,
          lib,
          system,
          ...
        }:
        let
          runtimeDeps = with pkgs; [
          ];

          buildDeps = with pkgs; [
            pkg-config
          ];

          devDeps = with pkgs; [
            # Libraries and programs needed for dev work; included in dev shell
            # NOT included in the nix build operation
            fish
            just
            nushell
            tailwindcss
            vscode-langservers-extracted
            zellij
          ];

          ldpath = with pkgs; [
            stdenv.cc.cc.lib
          ];

          mkDevShell =
            input:
            pkgs.mkShell {
              shellHook = ''
                # TODO: figure out if it's possible to remove this or allow a user's preferred shell
                exec env SHELL=${pkgs.fish}/bin/fish zellij --layout ./zellij_layout.kdl
              '';
              LD_LIBRARY_PATH = lib.makeLibraryPath ldpath;

              GIO_MODULE_DIR = "${pkgs.glib-networking}/lib/gio/modules/";

              RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
              buildInputs = runtimeDeps;
              nativeBuildInputs = buildDeps ++ devDeps;
            };

        in
        {

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ ];
            config = {
              allowUnfreePredicate =
                pkg:
                builtins.elem (lib.getName pkg) ([
                  "surrealdb"
                ]);
            };
          };

          packages.default = self'.packages.base;
          devShells.default = self'.devShells.stable;

          packages.base = ("");

          devShells.nightly = (mkDevShell (""));
          devShells.stable = (mkDevShell (""));
          devShells.msrv = (mkDevShell (""));
        };
    };
}
