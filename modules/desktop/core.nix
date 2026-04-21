# Module: modules/desktop/core.nix
# Purpose: Core desktop Home Manager apps/config (Waybar, Kitty, Wofi, GTK theming, cursors, wallpapers).
# Options: Uses modules.system.* to locate dotfiles for symlinks; no custom options defined here.
# Usage: Import in desktop profile/hosts to seed common desktop user environment.
{ config, pkgs, ... }:

let
  cfg = config.modules.system;
in
{
  home-manager.users.${cfg.mainUser} =
    { config, ... }:
    {
      home.packages = with pkgs; [
        file-roller
        gvfs
        hyprpaper
        hyprlock
        hypridle
        hyprshot
        hyprpicker
        kitty
        mako
        volantes-cursors
        wofi
        waybar
        firefox
        pavucontrol
        xclip
        cliphist
        wl-clipboard
        yazi
        vlc
        audacity
        gimp
        spotify
        discord
        teams-for-linux
        materia-theme
      ];

      gtk = {
        enable = true;
        theme = {
          name = "Materia-dark";
          package = pkgs.materia-theme;
        };
        gtk3.extraCss = ''
          @define-color accent_color #FD6AC0;
          @define-color selection_bg_color #FD6AC0;
          @define-color suggested_bg_color #FD6AC0;
          @define-color m3_sys_color_primary #FD6AC0;
        '';
        gtk4.extraCss = ''
          @define-color accent_color #FD6AC0;
          @define-color selection_bg_color #FD6AC0;
          @define-color suggested_bg_color #FD6AC0;
          @define-color m3_sys_color_primary #FD6AC0;
        '';
      };

      home.pointerCursor = {
        name = "volantes_cursors";
        package = pkgs.volantes-cursors;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };

      home.sessionVariables = {
        FZF_DEFAULT_OPTS = ''
          --color=fg:#C5C8C5,bg:#161718,hl:#FD6AC0
          --color=fg+:#FD6AC0,bg+:#444444,hl+:#161718
          --color=prompt:#FD6AC0,pointer:#FD6AC0,marker:#FD6AC0,spinner:#FD6AC0
          --color=info:#C5C8C5,header:#FD6AC0
          --color=border:#FD6AC0
        '';
      };

      home.file = {
        ".config/waybar/config".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/waybar/config";
        ".config/waybar/style.css".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/waybar/style.css";
        ".config/kitty/kitty.conf".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/kitty/kitty.conf";
        ".config/wofi/style.css".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/wofi/style.css";
        ".config/mako/config".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/mako/config";
        ".config/yazi/theme.toml".source =
          config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/desktop/yazi/theme.toml";

        "Pictures/wallpapers/wallpaper.png".source = ../../dotfiles/desktop/wallpapers/samurai.png;
        "Pictures/logo/logo.png".source = ../../dotfiles/desktop/splash/logo.png;
      };
    };

}
