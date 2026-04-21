# Module: modules/editors/neovim.nix
# Purpose: Enable Neovim via Home Manager with language runtimes and dotfile symlink.
# Options: No custom options; uses modules.system.mainUser and dotfilesPath for symlinks.
# Usage: Import in profiles/hosts to provide Neovim as primary editor with aliases.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} =
    { config, ... }:
    {
      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        withRuby = true;
        withNodeJs = true;
        withPython3 = true;
      };

      home.packages = with pkgs; [ ripgrep ];

      home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/nvim";

      programs.bash.shellAliases = {
        vimf = "vim $(fzf)";
      };

      programs.zsh.shellAliases = {
        vimf = "vim $(fzf)";
      };
    };
}
