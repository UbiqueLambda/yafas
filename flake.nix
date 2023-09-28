{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    yafas.url = "github:UbiqueLambda/yafas/next";
  };

  outputs = { nixpkgs, yafas, ... }@inputs:
    let
      someOverlay = _prev: _final: { };

      step0 =
        yafas.allLinux nixpkgs
          ({ pkgs, system }: { packages.default = pkgs.nixpkgs-fmt; formatter = pkgs.nixpkgs-fmt; });

      step1 = yafas.withAarch64Darwin nixpkgs
        (_prev: { pkgs, ... }: { packages.default = pkgs.nixpkgs-fmt; formatter = pkgs.nixpkgs-fmt; });

      step2 = yafas.withOverlays
        (_prev: { default = someOverlay; });

      step3 =
        yafas.withOverlay "cool"
          (_prev: someOverlay);

      step4 =
        yafas.withUniversals
          (_prev: { lib.hash = "sha256-"; });

      step5 =
        yafas.map
          (prev: prev // { lib.hash = prev.lib.hash + "YEAH"; });

      pipe = val: functions:
        let reverseApply = x: f: f x;
        in builtins.foldl' reverseApply val functions;
    in
    pipe step0
      [ step1 step2 step3 step4 step5 ];
}
