{
  description = "Personal Linux Home Manager rehearsal; build only, never activate";

  inputs = {
    # Official release branches inspected on 2026-10-03. A real Nix-generated
    # flake.lock is still required; these revision pins are not a substitute.
    nixpkgs.url = "github:NixOS/nixpkgs/774debe7a0d1b496e35677ad955a1011c6ff74f3";
    home-manager.url = "github:nix-community/home-manager/e5fcd298a00f08b6e8390baf04aa8edb62203070";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = false; };
        modules = [ ./nix/home.nix ./nix/rehearsal.nix ];
      };
    in {
      homeConfigurations = builtins.listToAttrs (map (system: {
        name = "rehearsal-${system}";
        value = mkHome system;
      }) systems);
      packages = builtins.listToAttrs (map (system: {
        name = system;
        value = { default = (mkHome system).activationPackage; };
      }) systems);
    };
}
