{
  description = "Basti - Securely connect to AWS resources in private VPCs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    basti-src = {
      url = "github:basti-app/basti";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, basti-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        basti = pkgs.buildNpmPackage rec {
          pname = "basti";
          version = "1.7.1";

          src = basti-src;

          npmDepsHash = "sha256-A9h/j4q6/wlHmRBTGpNTiO6manwgQsAUaHjWXKLHZ0k=";

          nativeBuildInputs = with pkgs; [
            nodejs_20
            python3
          ];

          buildPhase = ''
            runHook preBuild
            cd packages/basti
            npm run build-src
            cd ../..
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/basti
            cp -r packages/basti/dist $out/lib/node_modules/basti/
            cp -r packages/basti/bin $out/lib/node_modules/basti/
            cp packages/basti/package.json $out/lib/node_modules/basti/
            cp -r node_modules $out/lib/node_modules/basti/

            rm -rf $out/lib/node_modules/basti/node_modules/.bin
            rm -rf $out/lib/node_modules/basti/node_modules/basti
            rm -rf $out/lib/node_modules/basti/node_modules/basti-cdk
            rm -rf $out/lib/node_modules/basti/node_modules/docs

            mkdir -p $out/bin
            cat > $out/bin/basti <<EOF
            #!/bin/sh
            exec ${pkgs.nodejs_20}/bin/node $out/lib/node_modules/basti/bin/run.js "\$@"
            EOF
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
