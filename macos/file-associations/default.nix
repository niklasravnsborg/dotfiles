# Copied and modified from: https://discourse.nixos.org/t/how-to-create-macos-file-associations-with-nix-darwin/64801

# Determine the bundle bundle ID:
# $ mdls /Applications/IINA.app | grep kMDItemCF

# Determine the Uniform Type Identifier (UTI) of a file:
# $ mdls file.ext | grep kMDItemContentType

# Show configuration for extension:
# $ duti -x <ext>

# duti fails with error -50 for extensions that no installed app declares:
# on macOS 27 it resolves them to an invalid dynamic UTI. Pass the correct one instead:
# $ swift -e 'import UniformTypeIdentifiers; print(UTType(filenameExtension: "nix")!.identifier)'

{ pkgs, lib, ... }:
let
  dyn = {
    astro = "dyn.ah62d4rv4ge80c65ysm1u";
    bru = "dyn.ah62d4rv4ge80e6xz";
    fish = "dyn.ah62d4rv4ge80q4pxra";
    go = "dyn.ah62d4rv4ge80s52";
    mdx = "dyn.ah62d4rv4ge8043d2";
    nix = "dyn.ah62d4rv4ge8064p2";
    scss = "dyn.ah62d4rv4ge81g25xsq";
    toml = "dyn.ah62d4rv4ge81k55rru";
    tsx = "dyn.ah62d4rv4ge81k652";
    xsd = "dyn.ah62d4rv4ge81u65e";
    cs = "dyn.ah62d4rv4ge80g62";
    csproj = "dyn.ah62d4rv4ge80g65usm10y";
    razor = "dyn.ah62d4rv4ge81e2p4r73a";
    sln = "dyn.ah62d4rv4ge81g5ds";
    rules = "dyn.ah62d4rv4ge81e7pqqz3u";
  };
in
{
  home.packages = [
    pkgs.duti
  ];
  # Create a home activation script to apply duti settings
  home.activation = {
    setFileAssociation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting file associations with duti..."
      ${pkgs.duti}/bin/duti ~/.duti.conf
    '';
  };
  home.file = {
    ".duti.conf".text = ''
      # Web browser
      se.johnste.finicky http

      # Audio
      com.apple.QuickTimePlayerX flac all
      com.apple.QuickTimePlayerX mp3 all
      com.apple.QuickTimePlayerX ogg all
      com.apple.QuickTimePlayerX wav all

      # Video
      com.colliderli.iina avi all
      com.colliderli.iina mkv all
      com.colliderli.iina mov all
      com.colliderli.iina mp4 all
      com.colliderli.iina webm all
      com.colliderli.iina webp all

      # Most code related files
      dev.zed.Zed public.source-code all
      dev.zed.Zed public.plain-text all
      dev.zed.Zed ${dyn.astro} all
      dev.zed.Zed ${dyn.bru} all
      dev.zed.Zed css all
      dev.zed.Zed ${dyn.fish} all
      dev.zed.Zed ${dyn.go} all
      dev.zed.Zed json all
      dev.zed.Zed md all
      dev.zed.Zed ${dyn.mdx} all
      dev.zed.Zed mjs all
      dev.zed.Zed ${dyn.nix} all
      dev.zed.Zed php all
      dev.zed.Zed py all
      dev.zed.Zed ${dyn.scss} all
      dev.zed.Zed ${dyn.toml} all
      dev.zed.Zed ts all
      dev.zed.Zed ${dyn.tsx} all
      dev.zed.Zed yaml all

      # e.g. Makefile
      dev.zed.Zed public.make-source all

      # XML related
      com.microsoft.VSCode xml all
      com.microsoft.VSCode ${dyn.xsd} all

      # C# / .NET
      com.microsoft.VSCode ${dyn.cs} all
      com.microsoft.VSCode ${dyn.csproj} all
      com.microsoft.VSCode ${dyn.razor} all
      com.microsoft.VSCode ${dyn.sln} all

      # Firestore Rules (db.rules)
      # Currently only VSCode has the extension for viewing db.rules files
      com.microsoft.VSCode ${dyn.rules} all
    '';
  };
}
