# To disable the auto updater, run `claude config set --global autoUpdaterStatus disabled`

final: prev: {
  claude-code = final.stdenv.mkDerivation {
    name = "claude";
    version = "0.2.14";

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-0.2.14.tgz";
      sha256 = "sha256-+q1YgTSQFnldaOPi26FgKrE1mX4uQw73Y9wKD+BCXS4==";
    };

    buildInputs = with final; [
      nodejs_20
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp -r ./* $out/

      # Create a wrapper script
      cat > $out/bin/claude <<EOF
        #!/bin/sh
        # We have to set a system shell here because claude-code doesn't seem to be compatible with fish installed via nix.
        export SHELL=/bin/zsh
        exec ${final.nodejs_20}/bin/node $out/cli.mjs "\$@"
      EOF
      chmod +x $out/bin/claude
    '';
  };
}
