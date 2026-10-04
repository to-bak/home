;;; setup-magit.el --- Git, worktrees, and diff display -*- lexical-binding: t; -*-

(defun obp/magit-remember-worktree-project ()
  "Remember the Git worktree shown by Magit as a separate project."
  (when-let* ((root (magit-toplevel))
              ((file-regular-p (expand-file-name ".git" root)))
              (project (project-current nil root)))
    ;; A nested project or submodule must not register an unrelated parent root.
    (when (file-equal-p (project-root project) root)
      (project-remember-project project nil t))))

(use-package magit
  :bind (("C-x g" . magit-status)
         :map project-prefix-map
         ("m" . magit-project-status))
  :init
  ;; Switching projects opens Git status directly.
  (setq project-switch-commands #'magit-project-status)
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1
        magit-diff-refine-hunk t)
  (add-hook 'magit-status-mode-hook #'obp/magit-remember-worktree-project))

(use-package magit-delta
  :init
  ;; Keep native diffs available if delta is absent on another host.
  (when (executable-find "delta")
    (add-hook 'magit-mode-hook #'magit-delta-mode)))

(use-package git-gutter
  :hook (prog-mode . git-gutter-mode))

;;; setup-magit.el ends here
