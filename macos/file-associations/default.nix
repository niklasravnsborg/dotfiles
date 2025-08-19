# Copied and modified from: https://discourse.nixos.org/t/how-to-create-macos-file-associations-with-nix-darwin/64801

# Determine the bundle bundle ID:
# $ mdls /Applications/IINA.app | grep kMDItemCF

# Determine the Uniform Type Identifier (UTI) of a file:
# $ mdls file.ext | grep kMDItemContentType

# Show configuration for extension:
# $ duti -x <ext>

{ pkgs, lib, ... }:
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
      com.exafunction.windsurf public.source-code all
      com.exafunction.windsurf public.plain-text all
      com.exafunction.windsurf fish all
      com.exafunction.windsurf md all
      com.exafunction.windsurf mdx all
      com.exafunction.windsurf nix all
      com.exafunction.windsurf xml all

      # C# / .NET
      com.microsoft.VSCode cs all
      com.microsoft.VSCode csproj all
      com.microsoft.VSCode razor all
      com.microsoft.VSCode sln all
    '';
  };
}
