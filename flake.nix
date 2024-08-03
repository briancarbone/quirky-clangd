{
  description = "Quirky Clangd";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
      };

      mkEnv = name: ps:
        let
          stdenv = ps.stdenv;
        in
        {
          packages = {
            ${name} = stdenv.mkDerivation {
              inherit name;
              src = ./.;
              nativeBuildInputs = with pkgs; [
                meson
                ninja
                bear
              ];
            };
          };

          devShells = {
            ${name} = pkgs.mkShell.override {inherit stdenv; } {
              inputsFrom = [ self.packages.${system}.${name} ];
              packages = [ ps.clang-tools ];
              shellHook = ''
                rm -rf .cache bld compile_commands.json
                meson setup bld
                bear -- meson compile -C bld
              '';
            };
          };
        };

      versions = {
        "17" = pkgs.llvmPackages_17;
        "18" = pkgs.llvmPackages_18;
        "19" = pkgs.llvmPackages_19;
      };

      envs = pkgs.lib.mapAttrs mkEnv versions;
      merged = pkgs.lib.fold pkgs.lib.recursiveUpdate { } (pkgs.lib.attrValues envs);
    in
    {
      packages.${system} = merged.packages;
      devShells.${system} = merged.devShells;
    };
}
