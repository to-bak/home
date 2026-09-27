;;; evil-config.el --- Evil and package integrations -*- lexical-binding: t; -*-

;; Restore the modal editing setup from the pre-Meow configuration.  Keep
;; Evil-specific integration here so Org, Ghostel, and Agent Shell stay usable.

(defun obp/evil-delete-to-black-hole (args)
  "Use the black-hole register for a delete without an explicit register.
ARGS are the arguments passed to `evil-delete'.  Explicit registers keep
Evil's normal behavior."
  (unless (nth 3 args)
    (setf (nth 3 args) ?_))
  args)
(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-respect-visual-line-mode t
        evil-symbol-word-search t
        evil-kill-on-visual-paste nil)
  :config
  (evil-mode 1)
  (advice-add 'evil-delete :filter-args #'obp/evil-delete-to-black-hole)
  (keymap-set evil-insert-state-map "C-g" #'evil-normal-state)
  (keymap-set evil-motion-state-map "C-e" #'avy-goto-char-timer)
  (evil-global-set-key 'motion "j" #'evil-next-visual-line)
  (evil-global-set-key 'motion "k" #'evil-previous-visual-line)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (evil-collection-init))

(use-package evil-visualstar
  :after evil
  :demand t
  :config
  (global-evil-visualstar-mode))

(defun obp/save-and-kill-buffer ()
  "Save the current buffer to its file, then kill the buffer and window."
  (interactive)
  (save-buffer)
  (kill-buffer-and-window))

(evil-ex-define-cmd "q" #'kill-buffer-and-window)
(evil-ex-define-cmd "wq" #'obp/save-and-kill-buffer)

;; Keep the original Evil bindings for Org headings and metadata.
(with-eval-after-load 'org
  (evil-define-key '(normal insert visual) org-mode-map
    (kbd "C-j") #'org-next-visible-heading
    (kbd "C-k") #'org-previous-visible-heading
    (kbd "M-j") #'org-metadown
    (kbd "M-k") #'org-metaup))

(use-package evil-org
  :after evil
  :hook (org-mode . evil-org-mode)
  :config
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar))
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; The grouped agenda headers should not capture Evil's hjkl motions.
(setq org-super-agenda-header-map (make-sparse-keymap))

;; Ghostel ships this extension inside its repository.  Loading it from there
;; keeps the terminal integration alongside the installed Ghostel revision.
(with-eval-after-load 'ghostel
  (add-to-list 'load-path
               (expand-file-name
                "straight/repos/ghostel/extensions/evil-ghostel/"
                user-emacs-directory))
  (require 'evil-ghostel)
  (add-hook 'ghostel-mode-hook #'evil-ghostel-mode))

;; Preserve the prompt editing bindings from the pre-Meow Agent Shell setup.
(with-eval-after-load 'agent-shell
  (evil-define-key 'insert agent-shell-mode-map (kbd "RET") #'newline)
  (evil-define-key 'normal agent-shell-mode-map (kbd "RET") #'comint-send-input)
  (evil-define-key 'normal agent-shell-mode-map
    (kbd "TAB") #'agent-shell-ui-toggle-fragment)
  (evil-define-key 'insert agent-shell-mode-map
    (kbd "TAB") #'agent-shell-ui-toggle-fragment))

(provide 'evil-config)

;;; evil-config.el ends here
