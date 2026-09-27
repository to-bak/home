;;; ai-tooling-config.el --- Personal Emacs settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; AI tooling
;; ---------------------------------------------------------------------
(use-package gptel
  :config
  (when host/gptel-config
    (funcall host/gptel-config)))

(use-package agent-shell
  ;; :custom
  ;; (agent-shell-session-restore-verbosity 'full)
  :config
  ;; `agent-shell' starts completion from `post-self-insert-hook'.  Force the
  ;; newly inserted / or @ to be displayed before Corfu asks Emacs for its
  ;; screen position; without this, `posn-at-point' can transiently return nil.
  ;; (defun my-agent-shell-redisplay-before-triggering-completion (&rest _)
  ;;   "Redisplay input before `agent-shell' starts prefix completion."
  ;;   (redisplay t))
  ;; (advice-add 'agent-shell--trigger-completion-at-point :before
  ;;             #'my-agent-shell-redisplay-before-triggering-completion)

  (when host/agent-shell-config
    (funcall host/agent-shell-config))

  (keymap-set agent-shell-mode-map "C-c RET" #'newline))

(defun obp/agent-shell-file-completion-table (string predicate action)
  "Complete STRING as a filename for agent-shell.
PREDICATE and ACTION follow the completion table protocol.  In viewport or
minibuffer input, resolve paths relative to the associated shell buffer."
  (let ((source (agent-shell-completion--source-buffer)))
    (when (buffer-live-p source)
      (with-current-buffer source
        (completion-file-name-table string predicate action)))))

(defun obp/agent-shell-file-completion-exit (candidate status)
  "Add a space after completed file CANDIDATE, but not a directory.
STATUS is the completion exit status."
  (when (eq status 'finished)
    (let ((source (agent-shell-completion--source-buffer)))
      (unless (and (buffer-live-p source)
                   (with-current-buffer source
                     (file-directory-p
                      (substitute-in-file-name candidate))))
        (insert " ")))))

(defun obp/agent-shell-file-completion-at-point ()
  "Complete ordinary filesystem paths after @ in every agent shell.
Unlike agent-shell's project-file list, this supports directory-by-directory
navigation such as @~, @.., @../.., absolute paths, and non-project buffers."
  (when-let* ((bounds (agent-shell--completion-bounds "^ \t\n@" ?@)))
    (list (map-elt bounds :start)
          (map-elt bounds :end)
          #'obp/agent-shell-file-completion-table
          :exclusive 'no
          :category 'file
          :company-kind (lambda (candidate)
                          (if (string-suffix-p "/" candidate)
                              'folder
                            'file))
          :exit-function #'obp/agent-shell-file-completion-exit)))

(with-eval-after-load 'agent-shell-completion
  (advice-add 'agent-shell--file-completion-at-point :override
              #'obp/agent-shell-file-completion-at-point))

(with-eval-after-load 'agent-shell
  (keymap-set agent-shell-mode-map "C-c TAB" #'agent-shell-ui-toggle-fragment))

(use-package agent-shell-cockpit
  :straight (:type git
             :host github
             :repo "to-bak/agent-shell-cockpit"
             :branch "main")
  :after agent-shell
  :demand t
  :bind (("C-c m" . agent-shell-cockpit))
  :custom
  (agent-shell-cockpit-enable-standalone-sessions t)
  (agent-shell-cockpit-default-instructions '(cockpit))
  (agent-shell-cockpit-agent-preview-behavior 'delayed)
  (agent-shell-cockpit-context-directory-name "context")
  (agent-shell-cockpit-worktrees-directory-name "worktrees")
  (agent-shell-cockpit-worktree-open-function #'magit-status)
  (agent-shell-cockpit-repository-source-function
   #'project-prompt-project-dir)
  :config
  (require 'agent-shell-cockpit-org-roam)
  (setq agent-shell-cockpit-instructions
        '((manifest
           :title "AI Manifest"
           :source (org-roam "a8a767a1-1644-4c4a-a05f-23f7b3eab5bf")))))

(provide 'ai-tooling-config)

;;; ai-tooling-config.el ends here
