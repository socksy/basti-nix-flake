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

          npmWorkspace = "packages/basti";

          npmBuildScript = "build-src";

          postInstall = ''
            rm -rf $out/lib/node_modules/*/node_modules/{.bin,basti,basti-cdk,docs}
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
