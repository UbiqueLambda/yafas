# Yet Another For All Systems

[Pipe-optimized](https://github.com/NixOS/rfcs/pull/148) with-pattern-functions for making Nix-flakes' output easier to use.

E.g.:

```nix
{
  inputs = whatever0;

  outputs = { nixpkgs, yafas, ... }@inputs: 
    yafas.allLinux nixpkgs
       ({ pkgs, system }: { packages.default = whatever1; })
       |> yafas.withAarch64Darwin nixpkgs
         (_prev: { pkgs, ... }: { packages.default = whatever2; })
       |> yafas.withOverlays
         (_prev: { default = whatever3; })
       |> yafas.withOverlay "cool"
         (_prev: whatever3)
       |> yafas.withUniversals
         (_prev: { myLibs = whatever4; })
       |> yafas.map
         (prev: prev // { myLibs = prev.myLibs // { }; });
}
```

A minimalist example:

```nix
{
  inputs = whatever0;

  outputs = { nixpkgs, yafas, ... }@inputs: 
    yafas.withSystem "riscv64-linux" nixpkgs
      (_prev: { pkgs, ... }: { packages.default = whatever2; })
      {
        myLibs = whatever1;
      }
}
```

## Documentation

### Supported systems

We use [github.com:nix-systems/default](https://github.com/nix-systems/default) as `inputs.systems`, feel free to override it.

### Constructors

- `allDarwin: nixpkgs -> applier -> ouputs`
- `allLinux: nixpkgs -> applier -> ouputs`
- `allSystems: system[] -> nixpkgs -> applier -> ouputs`

Where `applier` is the lambda `{ pkgs, system }: { package.default = pkgs.callPackage ... { }; }`.

NOTE: These function will do a system-name injection, so all the outputs here have to be system-specific:
```
  packages.default = x; -> packages.${system}.default = x;
  formatter = y; -> formatter.${system} = y;
```

### Helpers

- `map: applier -> outputs -> x`

Where `applier` is a map applier.

### With per-system

- Multiple:
  - `withSystems: system[] -> nixpkgs -> applier -> outputs -> outputs`
  - `withDarwin: nixpkgs -> applier -> outputs -> outputs`
  - `withLinux: nixpkgs -> applier -> outputs -> outputs`

- Single:
  - `withSystem: system -> nixpkgs -> applier -> outputs -> outputs`
  - `withAarch64Linux: nixpkgs -> applier -> outputs -> outputs`
  - `withAMD64Linux: nixpkgs -> applier -> outputs -> outputs`
  - `withAarch64Darwin: nixpkgs -> applier -> outputs -> outputs`
  - `withAMD64Darwin: nixpkgs -> applier -> outputs -> outputs`

Where `applier` is the lambda `_prevOutputs: { pkgs, system }: { package.default = pkgs.callPackage ... { }; }`.

NOTE: Read [Constructors](#Constructors)' notes.

### With per-system products

- Generic:
  - `withNestedSystem: outputName -> applier -> outputs -> outputs`

- Specific:
  - `withApps: applier -> outputs -> outputs`
  - `withDevShells: applier -> outputs -> outputs`
  - `withLegacyPackages: applier -> outputs -> outputs`
  - `withPackages: applier -> outputs -> outputs`
  - `withFormatter: applier -> outputs -> outputs`

Where `applier` is the lambda `_prevOutputs: { pkgs, system }: { default = pkgs.callPackage ... { }; }`.

### With universals

- Generic:
  - `withUniversals: applier -> outputs -> outputs`
  - `withUniversal: outputName -> applier -> ouputs -> ouputs`

- Specific:
  - `withHomeManagerModules: applier -> ouputs -> ouputs`
  - `withNixOSModules: applier -> ouputs -> ouputs`
  - `withOverlays: applier -> ouputs -> ouputs`
  - `withSchemas: applier -> ouputs -> ouputs`

Where `applier` is the lambda `_prevOutputs: { <name> = <value>; }`.

### With universals products

- Generic:
  - `withNestedUniversal: outputName -> name -> outputs -> outputs`

- Specific:
  - `withHomeManagerModule: name -> outputs -> outputs`
  - `withNixOSModule: name -> outputs -> outputs`
  - `withOverlay: name -> outputs -> outputs`
  - `withSchema: name -> outputs -> outputs`

Where `applier` is the lambda `_prevOutputs: { <name> = <value>; }`.
