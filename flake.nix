{
  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/0.1.1.tar.gz";
    systems.url = "github:nix-systems/default";
  };
  outputs = { self, flake-schemas, systems }:
    let
      # lib
      inherit (builtins) attrNames elemAt filter foldl' head isAttrs
        length mapAttrs stringLength substring zipAttrsWith;

      update =
        a: b: if isAttrs b then recursiveUpdate a b else b;

      # nixpkgs clones
      hasSuffix = suffix: content:
        let
          lenContent = stringLength content;
          lenSuffix = stringLength suffix;
        in
        lenContent >= lenSuffix
        && substring (lenContent - lenSuffix) lenContent content == suffix;

      recursiveUpdateUntil = pred: lhs: rhs:
        let
          f = attrPath:
            zipAttrsWith (n: values:
              let here = attrPath ++ [ n ]; in
              if length values == 1
                || pred here (elemAt values 1) (head values) then
                head values
              else
                f here values
            );
        in
        f [ ] [ rhs lhs ];

      recursiveUpdate = lhs: rhs:
        recursiveUpdateUntil (path: lhs: rhs: !(isAttrs lhs && isAttrs rhs)) lhs rhs;

      # main functions
      support = targets: nixpkgs: applier:
        let
          eachSystem = system:
            let
              nestSystem = _: value: { ${system} = value; };

              systemOutputs = applier {
                inherit system;
                pkgs = nixpkgs.legacyPackages.${system};
              };
            in
            mapAttrs nestSystem systemOutputs;
        in
        zipAttrsWith
          (_: values: foldl' update { } values)
          (map eachSystem targets);

      support' = targets: nixpkgs: applier: accu:
        update accu (support targets nixpkgs (applier accu));

      withUniversal = output:
        applier: accu: accu // ({
          "${output}" =
            let
              new = applier accu;
            in
            if isAttrs new then
              update (accu.${output} or { }) new
            else new;
        });

      withNestedUniversal = output: name:
        applier: accu: accu // ({ "${output}" = (accu.${output} or { }) // { "${name}" = applier accu; }; });

      findSystems = accu:
        attrNames (accu.legacyPackages or accu.packages or accu.apps or accu.formatter or accu.devShells);

      withNestedSystem = name: nixpkgs: applier: accu:
        support (findSystems accu) accu nixpkgs
          ({ pkgs, system }@combo: {
            "${name}" = update accu.${name}.${system} (applier accu combo);
          });

      withSchemas = withUniversal "schemas";

      # system list
      importedSystems = import systems;
      linuxes = filter (hasSuffix "-linux") importedSystems;
      darwins = filter (hasSuffix "-darwin") importedSystems;
    in
    withSchemas (import ./schemas.nix flake-schemas) {
      # Constructors
      allSystems = support importedSystems;
      systems = support;
      system = target: support [ target ];

      allLinux = support linuxes;
      allDarwin = support darwins;

      # With per-system
      withSystems = support';
      withDarwin = support' darwins;
      withLinux = support' linuxes;
      withAllSystems = support' importedSystems;

      withSystem = target: support' [ target ];
      withAarch64Linux = support' [ "aarch64-linux" ];
      withAMD64Linux = support' [ "x86_64-linux" ];
      withAarch64Darwin = support' [ "aarch64-darwin" ];
      withAMD64Darwin = support' [ "x86_64-darwin" ];

      # With per-system products
      inherit withNestedSystem;
      withApps = withNestedSystem "apps";
      withDevShells = withNestedSystem "devShells";
      withLegacyPackages = withNestedSystem "legacyPackages";
      withPackages = withNestedSystem "packages";
      withFormatter = nixpkgs: applier: accu:
        support (findSystems accu) accu nixpkgs
          (combo: { formatter = applier combo; });

      # With universals
      withUniversals = applier: accu: accu // (applier accu);
      inherit withUniversal;
      withHomeManagerModules = withUniversal "homeManagerModules";
      withNixOSModules = withUniversal "nixosModules";
      withOverlays = withUniversal "overlays";
      inherit withSchemas;

      # With universals products
      inherit withNestedUniversal;
      withHomeManagerModule = withNestedUniversal "homeManagerModules";
      withNixOSModule = withNestedUniversal "nixosModules";
      withOverlay = withNestedUniversal "overlays";
      withSchema = withNestedUniversal "schemas";

      # Helpers
      map = applier: accu: applier accu;
    };
}
