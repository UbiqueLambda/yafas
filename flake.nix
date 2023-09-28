{
  inputs = { systems.url = "github:nix-systems/default"; };
  outputs = { self, systems }:
    let
      # lib
      inherit (builtins) filter foldl' mapAttrs stringLength substring zipAttrsWith;

      hasSuffix = suffix: content:
        let
          lenContent = stringLength content;
          lenSuffix = stringLength suffix;
        in
        lenContent >= lenSuffix
        && substring (lenContent - lenSuffix) lenContent content == suffix;

      # main functions
      support = targets: accu: nixpkgs: applier:
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
          (_: values: foldl' (a: b: a // b) { } values)
          (map eachSystem targets);

      support' = target: nixpkgs: applier: accu:
        support [ target ] accu nixpkgs (applier accu);

      withUniversal = output:
        applier: accu: accu // ({ "${output}" = (accu.${output} or { }) // applier accu; });

      withNestedUniversal = output: name:
        applier: accu: accu // ({ "${output}" = (accu.${output} or { }) // { "${name}" = applier accu; }; });

      # system list
      importedSystems = import systems;
      linuxes = filter (hasSuffix "-linux") importedSystems;
      darwins = filter (hasSuffix "-darwin") importedSystems;
    in
    {
      # constructors
      allLinux = support linuxes { };
      allDarwin = support darwins { };
      allSystems = support (linuxes ++ darwins) { };

      # pkgs-dependent
      withDarwin = support darwins;
      withLinux = support linuxes;

      withSystem = support';
      withAMD64Linux = support' "x86_64-linux";
      withAarch64Linux = support' "aarch64-linux";
      withAMD64Darwin = support' "x86_64-darwin";
      withAarch64Darwin = support' "aarch64-darwin";

      # universal attrset
      withOverlays = withUniversal "overlays";
      withSchemas = withUniversal "schemas";
      withNixOSModules = withUniversal "nixosModules";
      withHomeManagerModules = withUniversal "homeManagerModules";
      withUniversals = applier: accu: accu // (applier accu);

      # universal products
      withOverlay = withNestedUniversal "overlays";
      withSchema = withNestedUniversal "schemas";
      withNixOSModule = withNestedUniversal "nixosModules";
      withHomeManager = withNestedUniversal "homeManagerModules";

      # helper
      map = applier: accu: applier accu;
    };
}
