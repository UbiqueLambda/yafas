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
