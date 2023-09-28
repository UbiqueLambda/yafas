{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    yafas.url = "github:UbiqueLambda/yafas";
  };

  outputs = { nixpkgs, yafas, ... }@inputs:
    let
      whatever = "AAAAaaaaaaaaa";

      step0 =
        yafas.allLinux nixpkgs
          ({ pkgs, system }: { package.default = whatever; });

      step1 = yafas.withAarch64Darwin nixpkgs
        (_prev: { pkgs, ... }: { package.default = whatever; });

      step2 = yafas.withOverlays
        (_prev: { default = whatever; });

      step3 =
        yafas.withOverlay "cool"
          (_prev: whatever);

      step4 =
        yafas.withUniversals
          (_prev: { myLibs = whatever; });

      step5 =
        yafas.map
          (prev: prev // { myLibs = prev.myLibs // { }; });


      pipe = val: functions:
        let reverseApply = x: f: f x;
        in builtins.foldl' reverseApply val functions;
    in
    pipe step0
      [ step1 step2 step3 step4 step5 ];
}
