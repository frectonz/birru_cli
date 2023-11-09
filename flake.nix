{
  inputs = {
    opam-nix.url = "github:tweag/opam-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.follows = "opam-nix/nixpkgs";

    birru.url = "github:frectonz/birru";
  };
  outputs = { self, flake-utils, opam-nix, nixpkgs, birru }:
    let package = "birru";
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        on = opam-nix.lib.${system};

        devPackagesQuery = {
          ocaml-lsp-server = "*";
          ocamlformat = "*";
        };
        query = devPackagesQuery // {
          ocaml-base-compiler = "*";
        };

        scope = on.buildOpamProject' { } ./. query;
        overlay = final: prev: {
          ${package} = prev.${package}.overrideAttrs (_: {
            doNixSupport = false;
          });
        };

        scope' = scope.overrideScope' overlay;
        main = scope'.${package};
        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) scope');
      in
      {
        legacyPackages = scope';

        packages = {
          default = main;
          birru =
            let
              birru-server = birru.packages.${pkgs.system}.default;
              birru-client = main;
            in
            pkgs.writeShellScriptBin "birru" ''
              ${birru-server}/bin/birru > /dev/null &
              server_pid=$!

              ${birru-client}/bin/birru
              kill $server_pid
            '';
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ main ];
          buildInputs = devPackages ++ [ ];
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
