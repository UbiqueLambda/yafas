flake-schemas: outputs:
let
  fns = builtins.mapAttrs
    (name: _: {
      version = 1;
      doc = ''
        `${name}` lambda.
      '';
      inventory = _: { };
    })
    outputs;
in
fns // { inherit (flake-schemas.schemas) schemas; }
