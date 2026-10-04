;;; setup-evil.el --- Vim editing and package integrations -*- lexical-binding: t; -*-

(defun obp/evil-delete-to-black-hole (delete beg end &optional type register yank-handler)
  "Call DELETE with a black-hole register unless REGISTER is explicit."
  (funcall delete beg end type (or register ?_) yank-handler))

(use-package evil
  :demand t
  :hook ((org-capture-mode . evil-insert-state)
         (emacs-everywhere-mode . evil-insert-state))
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-respect-visual-line-mode t
        evil-symbol-word-search t
        evil-kill-on-visual-paste nil
        evil-undo-system 'undo-redo)
  :config
  (advice-add 'evil-delete :around #'obp/evil-delete-to-black-hole)
  (keymap-set evil-insert-state-map "C-g" #'evil-normal-state)
  (keymap-set evil-motion-state-map "C-e" #'avy-goto-char-timer)
  (evil-global-set-key 'motion "j" #'evil-next-visual-line)
  (evil-global-set-key 'motion "k" #'evil-previous-visual-line)
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (evil-collection-init))

(use-package evil-visualstar
  :after evil
  :demand t
  :config
  (global-evil-visualstar-mode 1))

(use-package evil-org
  :after evil
  :demand t
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; Ghostel includes this extension; use its installed copy rather than a package.
(use-package evil-ghostel
  :straight nil
  :after (ghostel evil)
  :load-path (lambda ()
               (expand-file-name
                "straight/repos/ghostel/extensions/evil-ghostel/"
                user-emacs-directory))
  :demand t
  :hook (ghostel-mode . evil-ghostel-mode))

;;; setup-evil.el ends here
