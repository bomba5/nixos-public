;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "bomba"
      user-mail-address "jhonata.poma@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-dracula)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(setq confirm-kill-emacs nil)           ; no prompt when quitting Emacs entirely

;; Disable evil-snipe which overrides 's' in normal mode
(remove-hook 'doom-first-input-hook #'evil-snipe-mode)
(remove-hook 'doom-first-input-hook #'evil-snipe-override-mode)

(after! evil-snipe
  (evil-snipe-mode -1)
  (evil-snipe-override-mode -1))

;; Restore normal Vim-style s
(after! evil
  (define-key evil-normal-state-map (kbd "s") #'evil-substitute))

;; Custom logo
(defun bomba-logo ()
  (let* ((banner '(" ▄▄▄▄    ▒█████   ███▄ ▄███▓ ▄▄▄▄    ▄▄▄      "
                   "▓█████▄ ▒██▒  ██▒▓██▒▀█▀ ██▒▓█████▄ ▒████▄    "
                   "▒██▒ ▄██▒██░  ██▒▓██    ▓██░▒██▒ ▄██▒██  ▀█▄  "
                   "▒██░█▀  ▒██   ██░▒██    ▒██ ▒██░█▀  ░██▄▄▄▄██ "
                   "░▓█  ▀█▓░ ████▓▒░▒██▒   ░██▒░▓█  ▀█▓ ▓█   ▓██▒"
                   "░▒▓███▀▒░ ▒░▒░▒░ ░ ▒░   ░  ░░▒▓███▀▒ ▒▒   ▓▒█░"
                   "▒░▒   ░   ░ ▒ ▒░ ░  ░      ░▒░▒   ░   ▒   ▒▒ ░"
                   " ░    ░ ░ ░ ░ ▒  ░      ░    ░    ░   ░   ▒   "
                   " ░          ░ ░         ░    ░            ░  ░"
                   "      ░                           ░           "))
         (longest-line (apply #'max (mapcar #'length banner)))
         ;; (pink '(:foreground "#FA73C2")))
         (green '(:foreground "#30C17E")))
    (dolist (line banner)
      (insert (propertize
               (+doom-dashboard--center
                +doom-dashboard--width
                (concat line (make-string (max 0 (- longest-line (length line))) 32)))
               'face green)
              "\n"))))

(setq +doom-dashboard-ascii-banner-fn #'bomba-logo)

;; Absolute current line number + relative other lines
(setq display-line-numbers-type 'relative
      display-line-numbers-current-absolute t)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)


(use-package ellama
  :ensure t
  :bind ("C-c e" . ellama)
  :init
  (require 'llm-ollama)
  ;; Default provider (Codellama:13b-instruct)
  (setopt ellama-provider
          (make-llm-ollama
           :scheme "http"
           :host "192.168.5.43"
           :port 11434
           :chat-model "Codellama:13b-instruct"
           :embedding-model "Codellama:13b-instruct"))
  ;; All available providers for easy switching
  (setopt ellama-providers
          `(("Llama2:7b" . ,(make-llm-ollama
                             :scheme "http"
                             :host "192.168.5.43"
                             :port 11434
                             :chat-model "Llama2:7b"
                             :embedding-model "Llama2:7b"))
            ("deepseek-coder:6.7b-instruct" . ,(make-llm-ollama
                                                :scheme "http"
                                                :host "192.168.5.43"
                                                :port 11434
                                                :chat-model "deepseek-coder:6.7b-instruct"
                                                :embedding-model "deepseek-coder:6.7b-instruct"))
            ("Codellama:13b-instruct" . ,(make-llm-ollama
                                          :scheme "http"
                                          :host "192.168.5.43"
                                          :port 11434
                                          :chat-model "Codellama:13b-instruct"
                                          :embedding-model "Codellama:13b-instruct"))
            ("starcoder2:7b" . ,(make-llm-ollama
                                 :scheme "http"
                                 :host "192.168.5.43"
                                 :port 11434
                                 :chat-model "starcoder2:7b"
                                 :embedding-model "starcoder2:7b"))
            ("Codellama:7b" . ,(make-llm-ollama
                                :scheme "http"
                                :host "192.168.5.43"
                                :port 11434
                                :chat-model "Codellama:7b"
                                :embedding-model "Codellama:7b"))
            ("mistral:7b" . ,(make-llm-ollama
                              :scheme "http"
                              :host "192.168.5.43"
                              :port 11434
                              :chat-model "mistral:7b"
                              :embedding-model "mistral:7b"))))
  :config
  (ellama-context-header-line-global-mode +1)
  (ellama-session-header-line-global-mode +1))
