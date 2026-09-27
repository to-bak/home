;;; version-control-config.el --- Personal version control settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Version control
;; ---------------------------------------------------------------------
;; https://www.reddit.com/r/emacs/comments/11auxod/magit_quits_after_a_commit_happen/
(defun obp/magit-remember-worktree-project ()
  "Remember the Git worktree opened in Magit as its own project."
  (require 'project)
  (when-let* ((root (magit-toplevel))
              ((file-regular-p (expand-file-name ".git" root)))
              (project (project-current nil root)))
    (when (file-equal-p (project-root project) root)
      (project-remember-project project nil t))))

(use-package magit
  :config
  (add-hook 'git-commit-post-finish-hook 'magit)
  (add-hook 'magit-status-mode-hook #'obp/magit-remember-worktree-project)
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; Add the explicit force option to Magit fetch.
(with-eval-after-load 'magit
  (transient-append-suffix 'magit-fetch "-t"
    '("-f" "Bypass safety checks" "--force")))

(use-package magit-delta
  :hook (magit-mode . magit-delta-mode))

;; Add magit to list of project commands
;; (add-to-list 'project-switch-commands '(magit-project-status "Magit" ?m))

;; Git gutter indicators
;; https://ianyepan.github.io/posts/emacs-git-gutter/
(use-package git-gutter
  :hook (prog-mode . git-gutter-mode)
  :config
  ;; Default is 0, meaning update indicators on saving the file.
  ;; (setq git-gutter:update-interval 0.02)
  )

(provide 'version-control-config)

;;; version-control-config.el ends here
