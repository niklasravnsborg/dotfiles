# GNOME settings for my NixOS desktop.
{
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:escape" ];
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = true;
      edge-tiling = true;
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = false;
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ "<Control><Super>Return" ];
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ "<Control><Super>Left" ];
      toggle-tiled-right = [ "<Control><Super>Right" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      # This is the shortcut to lock the screen
      screensaver = [ "<Control><Alt>q" ];
    };
  };
}
