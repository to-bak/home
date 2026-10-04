;;; org-workspaces-agent-shell.el --- Persist workspace agents in Org -*- lexical-binding: t; -*-
;; Package-Requires: ((emacs "29.1") (agent-shell "0.75.2"))
;;; Commentary:
;; Session entries hold backend identifiers, directory and session ID.
;; Configuration secrets and process objects are never serialized.
;; Background session references are queued and applied before a normal save
;; or explicitly with `org-workspaces-agent-shell-flush'. No automatic save.
;;; Code:
(require 'org-workspaces)
(require 'agent-shell)
(require 'map)
(require 'json)
(defvar-local org-workspaces-agent-shell-entry-id nil
  "Org ID for this buffer's session entry.")
(defvar-local org-workspaces-agent-shell-subscription nil
  "Subscription used to persist this buffer's session ID.")

(defvar-local org-workspaces-agent-shell-restoring nil
  "Non-nil until saved startup settings have been applied.")

(defvar org-workspaces-agent-shell-pending (make-hash-table :test 'equal)
  "Entry IDs mapped to pending property alists.
String values from older versions are treated as session IDs.")

(defun org-workspaces-agent-shell-flush ()
  "Apply queued session references to the current Org buffer.
Used before saving, or explicitly via C-c o w u.  Never writes the file itself."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Visit the workspace Org buffer to apply pending session references"))
  (unless (verify-visited-file-modtime (current-buffer))
    (user-error "Workspace file changed on disk; reconcile it before applying session references"))
  ;; Read the latest selections even for agents that do not emit option events.
  (dolist (buffer (buffer-list))
    (when (and (buffer-local-value 'org-workspaces-agent-shell-entry-id buffer)
               (with-current-buffer buffer (derived-mode-p 'agent-shell-mode)))
      (org-workspaces-agent-shell--record buffer)))
  (let (applied)
    (org-with-wide-buffer
     (org-map-entries
      (lambda ()
        (let* ((id (org-entry-get nil "ID"))
               (session (and id (gethash id org-workspaces-agent-shell-pending))))
          (when session
            (dolist (property (if (stringp session)
                                  (list (cons "OW_SESSION_ID" session)) session))
              (org-workspaces-put (point-marker) (car property) (cdr property)))
            (push id applied)))) nil nil))
    (dolist (id applied) (remhash id org-workspaces-agent-shell-pending))
    (when (called-interactively-p 'interactive)
      (message "Applied %d session reference(s); save normally" (length applied)))))

(defun org-workspaces-agent-shell--options ()
  "Read selected option IDs from the current agent, model first.
Only advertised select options are stored, never credentials or free text.
The private agent-shell accessors here also support legacy model/mode fields."
  (when (and (derived-mode-p 'agent-shell-mode)
             (bound-and-true-p agent-shell--state))
    (let ((state (agent-shell--state)) options)
      (dolist (option (agent-shell--config-options state))
        (when (and (equal (map-elt option :type) "select")
                   (not (member (map-elt option :category) '("model" "mode")))
                   (stringp (map-elt option :id))
                   (stringp (map-elt option :current-value)))
          (push (cons (map-elt option :id) (map-elt option :current-value)) options)))
      (append (when-let* ((model (agent-shell--current-model-id state)))
                (list (cons "model" model)))
              (when-let* ((mode (agent-shell--current-mode-id state)))
                (list (cons "mode" mode)))
              (nreverse options)))))

(defun org-workspaces-agent-shell--resume-config (config entry)
  "Copy CONFIG with ENTRY's saved choices as startup options.
Agent-shell applies these sequentially, reporting unavailable values itself."
  (if-let* ((saved (org-workspaces-get entry "OW_AGENT_OPTIONS")))
      (let* ((json-object-type 'alist) (json-key-type 'string)
             (options (json-read-from-string saved))
             (copy (copy-tree config)))
        (unless (and (listp options)
                     (cl-every (lambda (pair) (and (consp pair)
                                                  (stringp (car pair))
                                                  (stringp (cdr pair)))) options))
          (user-error "Invalid OW_AGENT_OPTIONS on saved session"))
        ;; The model must precede options such as reasoning, whose values may
        ;; depend on it. Do not let the user's global defaults overwrite these.
        (setq options (append (when-let* ((model (assoc "model" options))) (list model))
                              (cl-remove "model" options :key #'car :test #'equal)))
        (setf (alist-get :default-model-id copy) nil
              (alist-get :default-session-mode-id copy) nil
              (alist-get :default-config-options copy) (lambda () (copy-tree options)))
        copy)
    config))

(defun org-workspaces-agent-shell--record (buffer)
  "Queue BUFFER's session and selections without modifying its Org buffer."
  (with-current-buffer buffer
    (when-let* ((id org-workspaces-agent-shell-entry-id)
                ((not org-workspaces-agent-shell-restoring))
                (session (agent-shell-session-id :shell-buffer buffer))
                (entry (org-workspaces-find-id id)))
      (let* ((options (org-workspaces-agent-shell--options))
             (properties (append (list (cons "OW_SESSION_ID" session))
                                 (when options
                                   (list (cons "OW_AGENT_OPTIONS" (json-encode options)))))))
        (if (cl-every (lambda (property)
                        (equal (cdr property) (org-workspaces-get entry (car property))))
                      properties)
            (remhash id org-workspaces-agent-shell-pending)
          (unless (equal properties (gethash id org-workspaces-agent-shell-pending))
            (puthash id properties org-workspaces-agent-shell-pending)
            (with-current-buffer (marker-buffer entry)
              (add-hook 'before-save-hook #'org-workspaces-agent-shell-flush nil t))
            (message "Session settings ready for %s; save notes, or C-c o w u to apply them"
                     (buffer-name (marker-buffer entry)))))))))

(defun org-workspaces-agent-shell--options-updated (&rest args)
  "Queue confirmed settings from agent-shell's normalized state in ARGS."
  (when-let* ((state (plist-get args :state))
              (buffer (map-elt state :buffer))
              ((buffer-live-p buffer))
              ((buffer-local-value 'org-workspaces-agent-shell-entry-id buffer)))
    (org-workspaces-agent-shell--record buffer)))

(defun org-workspaces-agent-shell--on-kill ()
  "Capture the final selection before an associated agent buffer disappears."
  (when (derived-mode-p 'agent-shell-mode)
    (org-workspaces-agent-shell--record (current-buffer))))

(defun org-workspaces-agent-shell--track (buffer entry &optional restoring)
  "Connect BUFFER to ENTRY, optionally waiting for RESTORING to finish."
  (with-current-buffer buffer
    (when org-workspaces-agent-shell-subscription
      (agent-shell-unsubscribe :subscription org-workspaces-agent-shell-subscription))
    (setq org-workspaces-agent-shell-entry-id (org-workspaces-get entry "ID")
          org-workspaces-agent-shell-restoring restoring)
    (with-current-buffer (marker-buffer entry)
      (add-hook 'before-save-hook #'org-workspaces-agent-shell-flush nil t))
    (add-hook 'kill-buffer-hook #'org-workspaces-agent-shell--on-kill nil t)
    (setq org-workspaces-agent-shell-subscription
          (agent-shell-subscribe-to
           :shell-buffer buffer :event nil
           :on-event (lambda (event)
                       (when (eq (map-elt event :event) 'init-finished)
                         (with-current-buffer buffer
                           (setq org-workspaces-agent-shell-restoring nil)))
                       (when (memq (map-elt event :event)
                                   '(nil init-finished config-option-update turn-complete))
                         (org-workspaces-agent-shell--record buffer)))))
    (org-workspaces-agent-shell--record buffer)))

;; Successful setter responses need not emit config-option-update. These two
;; narrow state writers cover those responses, including changes from menus.
(dolist (function '(agent-shell--save-config-options agent-shell--config-option-set-value))
  (unless (advice-member-p #'org-workspaces-agent-shell--options-updated function)
    (advice-add function :after #'org-workspaces-agent-shell--options-updated)))

(defun org-workspaces-agent-shell--associate (buffer workspace name)
  "Associate BUFFER with WORKSPACE using NAME, preserving an existing entry."
  (let* ((config (agent-shell-get-config buffer))
         (identifier (map-elt config :identifier))
         (previous (buffer-local-value 'org-workspaces-agent-shell-entry-id buffer))
         (old (and previous (org-workspaces-find-id previous)))
         (directory (with-current-buffer buffer (agent-shell-cwd))))
    (unless identifier (user-error "Agent configuration has no stable identifier"))
    (when (and old (not (equal (org-with-point-at old (org-workspaces-current)) workspace)))
      (user-error "Session already belongs to another workspace; refile its Org entry first"))
    (let ((entry (or old
                     (org-workspaces-add-entry
                      workspace name "session"
                      `(("OW_AGENT" . ,(format "%s" identifier))
                        ("OW_DIRECTORY" . ,directory))))))
      (unless old
        (org-with-point-at entry
          (org-end-of-meta-data t)
          (insert (format "[[org-workspace-session:%s][Open agent session]]\n"
                          (org-workspaces-get entry "ID")))))
      (org-workspaces-agent-shell--track buffer entry)
      entry)))

(defun org-workspaces-agent-shell-associate ()
  "Associate an existing agent buffer with a workspace."
  (interactive)
  (let* ((source (current-buffer))
         (workspace (org-workspaces-resolve))
         (buffers (cl-remove-if-not
                   (lambda (buffer) (with-current-buffer buffer (derived-mode-p 'agent-shell-mode)))
                   (buffer-list)))
         (buffer (if (memq source buffers) source
                   (get-buffer (completing-read "Agent buffer: " (mapcar #'buffer-name buffers) nil t))))
         (name (read-string "Session name: " (and buffer (buffer-name buffer)))))
    (unless buffer (user-error "No agent buffer selected"))
    (org-workspaces-agent-shell--associate buffer workspace name)))

(defun org-workspaces-agent-shell--live (entry)
  "Find a live buffer associated with session ENTRY."
  (let ((id (org-workspaces-get entry "ID"))
        (session (org-workspaces-get entry "OW_SESSION_ID"))
        (agent (org-workspaces-get entry "OW_AGENT"))
        (directory (org-workspaces-directory entry)))
    (cl-find-if
     (lambda (buffer)
       (with-current-buffer buffer
         (and (derived-mode-p 'agent-shell-mode)
              (get-buffer-process buffer)
              (process-live-p (get-buffer-process buffer))
              (or (equal org-workspaces-agent-shell-entry-id id)
                  (and session (equal session (agent-shell-session-id :shell-buffer buffer))
                       (equal agent (format "%s" (map-elt (agent-shell-get-config buffer) :identifier)))
                       (equal directory (file-name-as-directory (agent-shell-cwd))))))))
     (buffer-list))))

(defun org-workspaces-agent-shell--saved-agent (identifier)
  "Resolve saved IDENTIFIER to exactly one configured agent without prompting."
  (unless (and identifier (not (string-empty-p identifier)))
    (user-error "Session has no saved OW_AGENT"))
  (let ((matches
         (cl-remove-if-not
          (lambda (config)
            (equal identifier (format "%s" (map-elt config :identifier))))
          (agent-shell--resolved-agent-configs))))
    (pcase (length matches)
      (0 (user-error "Saved agent %s is unavailable; restore its agent-shell configuration" identifier))
      (1 (car matches))
      (_ (user-error "Multiple agent configurations use identifier %s; give them unique identifiers" identifier)))))

(defun org-workspaces-agent-shell-open (&optional entry)
  "Open session ENTRY or select one from the current workspace.
Request the saved session and restore its saved model and select options.
Agent-shell reports any resumption or option failures in its buffer."
  (interactive)
  (let* ((entry (or entry
                    (and (derived-mode-p 'org-agenda-mode)
                         (when-let* ((id (org-get-at-bol 'org-workspaces-session-id)))
                           (org-workspaces-find-id id)))
                    (and (derived-mode-p 'org-mode)
                         (equal (org-entry-get nil "OW_KIND") "session") (point-marker))
                    (let* ((workspace (org-workspaces-resolve))
                           (choices (mapcar
                                     (lambda (marker)
                                       (cons (org-with-point-at marker
                                               (format "%s [%s]" (org-get-heading t t t t)
                                                       (org-entry-get nil "ID"))) marker))
                                     (org-workspaces-entries workspace "session"))))
                      (unless choices (user-error "No sessions; use C-c o w a or C-c o w n"))
                      (cdr (assoc (completing-read "Session: " choices nil t) choices)))))
         (live (org-workspaces-agent-shell--live entry)))
    (if live (pop-to-buffer live)
      (let* ((session (org-workspaces-get entry "OW_SESSION_ID"))
             (identifier (org-workspaces-get entry "OW_AGENT"))
             (default-directory (org-workspaces-directory entry))
             (directory default-directory)
             (agent-shell-cwd-function (lambda () directory))
             (config (org-workspaces-agent-shell--saved-agent identifier)))
        (unless session (user-error "No saved session ID; initialize and associate the agent first"))
        (unless (file-directory-p directory) (user-error "Worktree missing: %s" directory))
        (let ((buffer (agent-shell-start :config (org-workspaces-agent-shell--resume-config config entry)
                                         :session-id session)))
          (with-current-buffer buffer (setq-local agent-shell-cwd-function (lambda () directory)))
          (org-workspaces-agent-shell--track buffer entry t))))))

(defun org-workspaces-agent-shell-new ()
  "Start a new agent in a workspace directory, independently of Promptel."
  (interactive)
  (let* ((workspace (org-workspaces-resolve))
         (default-directory (org-workspaces-initialize workspace))
         (directory default-directory)
         (agent-shell-cwd-function (lambda () directory))
         (agent-shell-session-strategy 'new)
         (name (read-string "Session name: "))
         (buffer (agent-shell-start :config (agent-shell-select-config :prompt "Agent: "))))
    (with-current-buffer buffer (setq-local agent-shell-cwd-function (lambda () directory)))
    (org-workspaces-agent-shell--associate buffer workspace name)))

(defun org-workspaces-agent-shell-delivered (buffer routing)
  "Associate delivered BUFFER when opaque ROUTING identifies a workspace."
  (when-let* ((id (plist-get routing :workspace-id)))
    (if-let* ((workspace (org-workspaces-find-id id)))
        (condition-case err
            (org-workspaces-agent-shell--associate buffer workspace (buffer-name buffer))
          (error (display-warning 'org-workspaces (format "Prompt delivered, but association failed: %s" err))))
      (display-warning 'org-workspaces "Prompt delivered, but workspace heading was not found"))))

(defun org-workspaces-agent-shell--status-label (buffer)
  "Return a styled status label for live BUFFER, or a saved session."
  (let* ((status (and buffer (agent-shell-status :shell-buffer buffer)))
         (label (pcase status ('busy "RUNNING") ('blocked "APPROVAL")
                       ('ready "IDLE") (_ "SAVED")))
         (face (pcase status ('busy 'success) ('blocked 'warning)
                      ('ready 'org-done) (_ 'shadow))))
    (propertize (format "%-8s" label) 'face face)))

(defun org-workspaces-agent-shell-workspace-rows (workspace)
  "Render live and saved sessions belonging to WORKSPACE without editing it."
  (let ((workspace-id (org-workspaces-get workspace "ID")))
    (mapconcat
     (lambda (entry)
       (let* ((id (org-workspaces-get entry "ID"))
              (live (org-workspaces-agent-shell--live entry))
              (saved (org-workspaces-get entry "OW_SESSION_ID"))
              (name (org-with-point-at entry (org-get-heading t t t t))))
         (propertize
          (format "      %s  %s%s\n"
                  (if (or live saved)
                      (org-workspaces-agent-shell--status-label live)
                    (propertize "UNSAVED " 'face 'warning))
                  name (if (or live saved) "" " (no session ID)"))
          'org-workspaces-id workspace-id
          'org-workspaces-session-id id
          'org-workspaces-open-function
          (lambda ()
            (let ((target (org-workspaces-find-id id)))
              (unless target (user-error "Session entry missing; refresh with g"))
              (org-workspaces-agent-shell-open target)))
          'mouse-face 'highlight
          'help-echo "RET or TAB: open or resume this session")))
     (org-workspaces-entries workspace "session") "")))

(defun org-workspaces-agent-shell-agenda-section ()
  "Return agents processing or awaiting approval for the workspace agenda.
Statuses are sampled on agenda creation and refresh; no Org files are edited."
  (let ((rows
         (cl-loop for buffer in (buffer-list)
                  when (with-current-buffer buffer
                         (and (derived-mode-p 'agent-shell-mode)
                              (get-buffer-process buffer)
                              (process-live-p (get-buffer-process buffer))
                              (memq (agent-shell-status :shell-buffer buffer)
                                    '(busy blocked))))
                  collect
                  (let* ((target buffer)
                         (entry-id (buffer-local-value 'org-workspaces-agent-shell-entry-id buffer))
                         (entry (and entry-id (org-workspaces-find-id entry-id)))
                         (workspace (and entry (org-with-point-at entry (org-workspaces-current))))
                         (workspace-id (and workspace (org-workspaces-get workspace "ID")))
                         (workspace-name (if workspace
                                             (org-with-point-at workspace (org-get-heading t t t t))
                                           "Unassociated"))
                         (name (if entry (org-with-point-at entry (org-get-heading t t t t))
                                 (buffer-name buffer))))
                    (propertize
                     (format "  %s  %s  %s\n"
                             (org-workspaces-agent-shell--status-label buffer)
                             name (propertize workspace-name 'face 'shadow))
                     'org-workspaces-id workspace-id
                     'org-workspaces-session-id entry-id
                     'org-workspaces-open-function
                     (lambda ()
                       (if (buffer-live-p target)
                           (pop-to-buffer target)
                         (if-let* ((saved (and entry-id (org-workspaces-find-id entry-id))))
                             (org-workspaces-agent-shell-open saved)
                           (user-error "Session buffer was closed; refresh with g"))))
                     'mouse-face 'highlight
                     'help-echo "RET or TAB: open this agent session")))))
    (concat (propertize "⚡ Running agents\n" 'face 'org-agenda-structure)
            (if rows (apply #'concat rows)
              (propertize "  No agents running\n" 'face 'shadow))
            "\n" (org-workspaces-agenda-separator))))

(add-hook 'org-workspaces-agenda-sections-functions
          #'org-workspaces-agent-shell-agenda-section)
(add-hook 'org-workspaces-agenda-workspace-functions
          #'org-workspaces-agent-shell-workspace-rows)

(org-link-set-parameters
 "org-workspace-session"
 :follow (lambda (id _argument)
           (let ((entry (org-workspaces-find-id id)))
             (unless entry (user-error "Session entry missing: %s" id))
             (org-workspaces-agent-shell-open entry))))

(with-eval-after-load 'promptel-agent-shell
  (add-hook 'promptel-agent-shell-delivered-functions #'org-workspaces-agent-shell-delivered))
(define-key org-workspaces-map (kbd "u") #'org-workspaces-agent-shell-flush)
(define-key org-workspaces-map (kbd "a") #'org-workspaces-agent-shell-associate)
(define-key org-workspaces-map (kbd "s") #'org-workspaces-agent-shell-open)
(define-key org-workspaces-map (kbd "n") #'org-workspaces-agent-shell-new)
(provide 'org-workspaces-agent-shell)
;;; org-workspaces-agent-shell.el ends here
