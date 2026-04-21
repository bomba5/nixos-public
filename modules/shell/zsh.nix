# Module: modules/shell/zsh.nix
# Purpose: Set Zsh as main shell with Oh My Zsh + powerlevel10k, fonts, and git token sourcing.
# Options: No custom options; uses modules.system.mainUser/dotfilesPath for files.
# Usage: Imported via base profile to give the main user a configured Zsh environment.
{ config, pkgs, ... }:

let
  cfg = config.modules.system;
in
{
  programs.zsh.enable = true;
  users.users.${cfg.mainUser}.shell = pkgs.zsh;

  home-manager.users.${cfg.mainUser} =
    { config, ... }:
    {
      home.packages = with pkgs; [
        powerline-fonts
        nerd-fonts.fira-code
      ];

      home.file.".p10k.zsh".source =
        config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/dotfiles/zsh/p10k.zsh";

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        dotDir = ".config/zsh";

        initContent = ''
          if [[ -f ~/.config/github-token.env ]]; then
            source ~/.config/github-token.env
          fi
          if [[ -f ~/.p10k.zsh ]]; then
            source ~/.p10k.zsh
          fi
          export GPG_TTY=$(tty)
          (( ''${+commands[kitty]} )) && alias ssh='kitty +kitten ssh'
        '';

        oh-my-zsh = {
          enable = true;
          theme = "powerlevel10k/powerlevel10k";
          plugins = [
            "git"
            "vi-mode"
            "sudo"
          ];
          custom = "$HOME/.oh-my-zsh/custom";
        };
      };

      # Ensure powerlevel10k is installed and available to Zsh
      home.file.".oh-my-zsh/custom/themes/powerlevel10k".source = pkgs.fetchFromGitHub {
        owner = "romkatv";
        repo = "powerlevel10k";
        rev = "v1.19.0";
        sha256 = "sha256-+hzjSbbrXr0w1rGHm6m2oZ6pfmD6UUDBfPd7uMg5l5c=";
      };
    };
}
