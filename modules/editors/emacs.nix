# Module: modules/editors/emacs.nix
# Purpose: Provide Doom Emacs setup via Home Manager with supporting tools and bootstrap hook.
# Options: No custom options; uses modules.system.mainUser/dotfilesPath for Doom config symlinks.
# Usage: Import on hosts where Doom Emacs should be available; ensures auto-clone on first activation.
{ config, pkgs, lib, ... }:

let
  sysCfg = config.modules.system;
in
{
  home-manager.users.${sysCfg.mainUser} =
    { config, ... }:
    let
      doomEmacsDir = "${config.home.homeDirectory}/.config/emacs";
    in
    {
      home.packages = with pkgs; [
        (emacsPackagesFor pkgs.emacs).emacs
        git
        fd
        nixd
        shfmt
        ispell
        ripgrep
        rustfmt
        clang-tools
        rust-analyzer
        nixfmt-classic
        bash-language-server
        ccls
      ];

      home.file = {
        ".doom.d/init.el".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/dotfiles/doom/init.el";
        ".doom.d/config.el".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/dotfiles/doom/config.el";
        ".doom.d/packages.el".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/dotfiles/doom/packages.el";
      };

      # Auto-install Doom on first login (or use manual bootstrap once)
      home.activation.doomBootstrap = ''
        export PATH="${pkgs.git}/bin:$PATH:${pkgs.emacs}/bin:$PATH"

        if [ ! -d "${doomEmacsDir}" ]; then
          git clone --depth=1 https://github.com/doomemacs/doomemacs ${doomEmacsDir}
        fi
      '';

      home.sessionVariables = {
        PATH = "${doomEmacsDir}/bin:$PATH";
      };

      programs.bash.shellAliases = {
        ee = "emacs -nw";
        eef = "emacs -nw $(fzf)";
      };

      programs.zsh.shellAliases = {
        ee = "emacs -nw";
        eef = "emacs -nw $(fzf)";
      };
    };
}
