# Module: modules/editors/vim.nix
# Purpose: Configure classic Vim with plugins and dotfile symlinks via Home Manager.
# Options: No custom options; uses modules.system.mainUser/dotfilesPath for sources.
# Usage: Import when Vim is desired alongside or instead of Neovim.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} =
    { config, ... }:
    {
      programs.vim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vim-airline
          vim-airline-themes
          dracula-vim
          nerdtree
          fzf-vim
          auto-pairs
          vim-indent-guides
          coc-nvim
          vim-gitgutter
          nerdtree-git-plugin
        ];

        extraConfig = builtins.readFile ../../dotfiles/vim/vimrc;
      };

      home.file = {
        ".vimrc".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/vim/vimrc";
        ".vim/coc-settings.json".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/vim/coc-settings.json";
      };

      programs.bash.shellAliases = {
        vimf = "vim $(fzf)";
      };

      programs.zsh.shellAliases = {
        vimf = "vim $(fzf)";
      };
    };
}
