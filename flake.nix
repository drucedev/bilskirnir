{
  description = "Bilskirnir checks and Qt tooling (qs comes from the system)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          gnumake
          nodejs
          qt6.qtdeclarative
          shellcheck
          shfmt
        ];

        # Keep static import metadata matched to the Qt tools, without replacing system qs.
        BILSKIRNIR_QML_IMPORT_PATH = pkgs.lib.makeSearchPath "lib/qt-6/qml" [
          pkgs.qt6.qtdeclarative
          pkgs.quickshell
        ];
      };
    };
}
