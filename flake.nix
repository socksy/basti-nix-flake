{
  description = "Basti - Securely connect to AWS resources in private VPCs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        basti = pkgs.buildNpmPackage rec {
          pname = "basti";
          version = "1.7.1";

          src = ../basti;

          npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

          nativeBuildInputs = with pkgs; [
            nodejs_20
            python3
          ];

          buildInputs = with pkgs; [
            nodePackages.typescript
          ];

          preBuild = ''
            npm run build-src
          '';

          dontNpmBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/basti
            cp -r . $out/lib/node_modules/basti

            mkdir -p $out/bin
            ln -s $out/lib/node_modules/basti/packages/basti/bin/run.js $out/bin/basti
            chmod +x $out/bin/basti

            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Securely connect to RDS, Elasticache, and other AWS resources in VPCs with no idle cost";
            homepage = "https://github.com/basti-app/basti";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.unix;
          };
        };
      in
      {
        packages.default = basti;

        apps.default = {
          type = "app";
          program = "${basti}/bin/basti";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            basti
            pkgs.awscli2
          ];
        };
      }
    );
}
