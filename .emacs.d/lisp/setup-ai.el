;;; setup-ai.el --- Chat and agent workflows -*- lexical-binding: t; -*-

(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :bind (("C-c j" . gptel-menu)
         ("C-c M-j" . gptel))
  :config
  (when host/gptel-config
    (funcall host/gptel-config)))

(defun obp/agent-shell-file-completion-table (string predicate action)
  "Complete filenames relative to the shell supplying this input's context."
  (when-let* ((source (agent-shell-completion--source-buffer)))
    (with-current-buffer source
      (completion-file-name-table string predicate action))))

(defun obp/agent-shell-file-completion-exit (candidate status)
  "Quote completed file CANDIDATE and add a space when STATUS is finished.
Leave directories open for further completion."
  (when (eq status 'finished)
    (when-let* ((source (agent-shell-completion--source-buffer)))
      (unless (with-current-buffer source
                (file-directory-p (substitute-in-file-name candidate)))
        (agent-shell--capf-exit-with-file-mention candidate status)))))

(defun obp/agent-shell-file-completion-at-point ()
  "Complete filesystem paths after @, including paths outside the project."
  (when-let* ((source (agent-shell-completion--source-buffer))
              (bounds (agent-shell--completion-bounds "^ \t\n@\"" ?@)))
    (list (map-elt bounds :start) (map-elt bounds :end)
          #'obp/agent-shell-file-completion-table
          :exclusive 'no
          :category 'file
          :exit-function #'obp/agent-shell-file-completion-exit)))

(use-package agent-shell
  :commands (agent-shell agent-shell-openai-start-codex)
  :hook ((agent-shell-mode . obp/hide-line-numbers)
         (agent-shell-mode . completion-preview-mode))
  :bind (:map agent-shell-mode-map
         ("C-c RET" . newline)
         ("C-c TAB" . agent-shell-ui-toggle-fragment))
  :config
  ;; This Shell Maker version interpolates a keymap object as executable code.
  ;; Regenerate the mode through its public API using the map's symbol instead.
  (shell-maker-define-major-mode (agent-shell--make-shell-maker-config)
                                'agent-shell-mode-map)
  (when host/agent-shell-config
    (funcall host/agent-shell-config))
  ;; The package exposes no option to replace its project-file completion table.
  ;; Retain one narrow override so shell, viewport and queued inputs all agree.
  (with-eval-after-load 'agent-shell-completion
    (advice-add 'agent-shell--file-completion-at-point :override
                #'obp/agent-shell-file-completion-at-point)))

(use-package agent-shell-cockpit
  :straight (:type git :host github :repo "to-bak/agent-shell-cockpit"
             :branch "main")
  :bind ("C-c m" . agent-shell-cockpit)
  :custom
  (agent-shell-cockpit-default-instructions '(cockpit))
  (agent-shell-cockpit-agent-preview-behavior 'delayed)
  (agent-shell-cockpit-context-directory-name "context")
  (agent-shell-cockpit-worktrees-directory-name "worktrees")
  (agent-shell-cockpit-worktree-open-function #'magit-status)
  (agent-shell-cockpit-repository-source-function #'project-prompt-project-dir))

;;; setup-ai.el ends here
