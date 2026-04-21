# Module: modules/shell/fish.nix
# Purpose: Configure Fish shell with aliases/themes and set as main shell for the primary user.
# Options: No custom options; uses modules.system.mainUser for user selection.
# Usage: Import on hosts where Fish should replace Zsh/Bash for the main user.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} = {
    home.packages = with pkgs; [
      powerline-fonts
      nerd-fonts.fira-code
      fishPlugins.bobthefish
    ];

  };

  programs.fish = {
    enable = true;
    shellAbbrs = {
      g = "git";
      l = "ls -ltr";
    };

    interactiveShellInit = ''
      set -g fish_greeting
      set -g theme_color_scheme gruvbox
      set -g theme_display_git yes
      set -g theme_display_virtualenv yes
      set -g theme_powerline_fonts yes
      set -g theme_nerd_fonts yes
      if test -f ~/.config/github-token.env
        source ~/.config/github-token.env
      end
    '';
  };

  users.users.${sysCfg.mainUser}.shell = pkgs.fish;
}
