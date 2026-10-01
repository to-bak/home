;;; setup-embark.el --- Context actions and candidate export -*- lexical-binding: t; -*-

(defun obp/embark-delete-line ()
  "Remove the current result line without modifying its source file."
  (interactive)
  (unless (and buffer-read-only
               (derived-mode-p 'embark-collect-mode 'grep-mode 'occur-mode))
    (user-error "This command is for read-only search-result buffers"))
  (let ((inhibit-read-only t))
    (delete-region (line-beginning-position)
                   (min (point-max) (1+ (line-end-position))))))

(defun obp/embark-export-bindings ()
  "Enable result-line removal in exported search buffers."
  (when (derived-mode-p 'grep-mode 'occur-mode)
    (use-local-map (copy-keymap (current-local-map)))
    (local-set-key (kbd "C-c C-d") #'obp/embark-delete-line)))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings)
         :map minibuffer-local-map
         ("C-c C-o" . embark-export))
  :hook ((embark-collect-mode . hl-line-mode)
         (embark-after-export . obp/embark-export-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (keymap-set embark-collect-mode-map "C-c C-d" #'obp/embark-delete-line))

;; Embark loads this integration automatically once Consult is loaded.
(use-package embark-consult)

;;; setup-embark.el ends here
