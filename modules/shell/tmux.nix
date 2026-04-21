# Module: modules/shell/tmux.nix
# Purpose: Configure tmux with some customs for the primary user.
# Options: No custom options.
# Usage: Import on hosts where tmux is wanted.
{
  programs.tmux = {
    enable = true;

    extraConfig = ''
      ##### Prefix: Ctrl-Space
      set -g prefix C-Space
      unbind C-b
      bind C-Space send-prefix

      ##### Make tmux feel instant
      set -g repeat-time 300
      set -sg escape-time 0

      ##### Vim-like splits
      unbind '"'
      unbind %
      bind | split-window -h
      bind - split-window -v

      ##### Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display-message 'reloaded tmux config'

      ##### Enable mouse
      set -g mouse on

      # Auto-enter copy-mode when scrolling up
      bind -n WheelUpPane if -F "#{mouse_any_flag}" \
        "send-keys -M" \
        "copy-mode -e; send-keys -M"

      bind -n WheelDownPane send-keys -M

      ##### Large scrollback (useful for builds/logs)
      set -g history-limit 200000

      ##### Vim-style copy mode
      setw -g mode-keys vi

      ##### Status bar base
      set -g status on
      set -g status-position bottom
      set -g status-interval 5
      set -g status-style "bg=#161718,fg=#c4c8c5"

      ##### Left: session name (accent)
      set -g status-left-length 40
      set -g status-left "#[fg=#161718,bg=#FD6AC0,bold] #S #[default]"

      ##### Right: host + time
      set -g status-right-length 80
      set -g status-right "#[fg=#c4c8c5,bg=#161718]#H #[fg=#999999]%Y-%m-%d %H:%M #[default]"

      ##### Window styling
      set -g window-status-style "fg=#c4c8c5,bg=#161718"
      set -g window-status-current-style "fg=#161718,bg=#FD6AC0,bold"
      set -g window-status-format " #I:#W "
      set -g window-status-current-format " #I:#W "

      ##### Activity indicator
      set -g window-status-activity-style "fg=#FD6AC0,bg=#161718,bold"
      set -g monitor-activity on

      ##### Pane borders
      set -g pane-border-style "fg=#FD6AC0"
      set -g pane-active-border-style "fg=#FD6AC0"

      ##### Message styling (command prompt / reload msg)
      set -g message-style "bg=#161718,fg=#FD6AC0,bold"

      ##### Copy-mode selection styling
      set -g mode-style "bg=#FD6AC0,fg=#161718,bold"
    '';
  };
}
