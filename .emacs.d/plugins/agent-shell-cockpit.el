;;; agent-shell-cockpit.el --- Focused dashboard for agent-shell -*- lexical-binding: t; -*-

;; Author: to-bak
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1") (agent-shell "0.1"))
;; Keywords: convenience, tools

;;; Commentary:

;; A compact, agenda-inspired overview of live `agent-shell' sessions.
;; It answers two questions: which agents need attention, and which are still
;; working?  The cockpit deliberately keeps its action surface small.
;;
;; Invoke `agent-shell-cockpit' to show the dashboard in the selected window.
;; Window-management integrations belong in user configuration.  From a
;; session row:
;;
;;   C-j / C-k  Move between sessions and preview them on the right
;;   TAB / RET  Focus the selected session on the right
;;   r          Refresh
;;   c          Create a session with the configured default agent
;;   C          Create a session and choose its ACP client
;;   x          Kill the selected session
;;   n          Next session
;;   p          Previous session
;;   q          Quit the cockpit
;;
;; The `h', `j', `k', and `l' keys are intentionally left untouched for Evil.

;;; Code:

(require 'agent-shell)
(require 'map)
(require 'seq)
(require 'subr-x)

(declare-function agent-shell-buffers "agent-shell" ())
(declare-function agent-shell-status "agent-shell" (&key shell-buffer))
(declare-function agent-shell-new-shell "agent-shell" ())
(defvar agent-shell--state)

(defgroup agent-shell-cockpit nil
  "A compact dashboard for `agent-shell'."
  :group 'agent-shell
  :prefix "agent-shell-cockpit-")

(defcustom agent-shell-cockpit-buffer-name "*Agent Shell Cockpit*"
  "Name of the cockpit buffer."
  :type 'string
  :group 'agent-shell-cockpit)

(defcustom agent-shell-cockpit-refresh-interval 2
  "Seconds between refreshes while the cockpit is visible.
Set to nil to disable automatic refreshes."
  :type '(choice (const :tag "Disabled" nil)
                 (number :tag "Seconds"))
  :group 'agent-shell-cockpit)

(defcustom agent-shell-cockpit-width 0.5
  "Width of a newly-created cockpit window.
 A float means a fraction of the frame width; an integer is a column count.
 The remaining width is used for the agent window."
  :type '(choice (float :tag "Frame fraction")
                 (integer :tag "Columns"))
  :group 'agent-shell-cockpit)

(defcustom agent-shell-cockpit-default-command #'agent-shell-new-shell
  "Interactive command used by `agent-shell-cockpit-create'.
Set this to an agent-specific starter such as
`agent-shell-openai-start-codex'.  Use
`agent-shell-cockpit-create-new' to always choose an ACP client."
  :type 'function
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-title
  '((t :inherit (error fixed-pitch) :weight bold :height 1.7))
  "Face for the cockpit ASCII art.
This uses only built-in Emacs faces so themes can supply the error color."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-heading
  '((t :inherit bold))
  "Face for section headings."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-secondary
  '((t :inherit shadow))
  "Face for secondary information."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-session-title
  '((t :inherit font-lock-function-name-face :weight semi-bold))
  "Face for an agent-generated session title."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-status-attention
  '((t :inherit error :weight bold :box (:line-width (1 . -1))))
  "Face for sessions that need user attention."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-status-working
  '((t :inherit warning :weight bold :box (:line-width (1 . -1))))
  "Face for working sessions."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-status-ready
  '((t :inherit success :weight bold :box (:line-width (1 . -1))))
  "Face for ready sessions."
  :group 'agent-shell-cockpit)

(defface agent-shell-cockpit-status-muted
  '((t :inherit shadow :box (:line-width (1 . -1))))
  "Face for starting, stopped, or unknown sessions."
  :group 'agent-shell-cockpit)

(defvar agent-shell-cockpit--buffer nil
  "The live cockpit buffer, or nil.")

(defvar-local agent-shell-cockpit--refresh-timer nil
  "Automatic refresh timer owned by the current cockpit buffer.")

(defvar-local agent-shell-cockpit--selected-buffer nil
  "Session row most recently selected in the current cockpit buffer.")

(defconst agent-shell-cockpit--ascii-art
  '("   .---------------."
    "  / .-----------.  \\"
    " / /   _     _    \\ \\"
    "| |   (_)   (_)    | |"
    "| |  .-------.     | |"
    " \\ \\ '-------'    / /"
    "  '---------------'"))

(defconst agent-shell-cockpit--status-spec
  '((attention "[NEEDS ATTENTION]" agent-shell-cockpit-status-attention 0)
    (working   "[WORKING]"         agent-shell-cockpit-status-working   1)
    (ready     "[READY]"           agent-shell-cockpit-status-ready     2)
    (starting  "[STARTING]"        agent-shell-cockpit-status-muted     3)
    (stopped   "[STOPPED]"         agent-shell-cockpit-status-muted     4)
    (unknown   "[UNKNOWN]"         agent-shell-cockpit-status-muted     5))
  "Display label, face, and sort rank for each cockpit status.")

(defun agent-shell-cockpit--buffers ()
  "Return the live `agent-shell' buffers."
  (seq-filter #'buffer-live-p (agent-shell-buffers)))

(defun agent-shell-cockpit--process-dead-p (buffer)
  "Return non-nil when BUFFER has an associated process that has died.
An absent process is not considered dead because a new shell may still be
initializing."
  (when-let* ((process (get-buffer-process buffer)))
    (not (process-live-p process))))

(defun agent-shell-cockpit--status (buffer)
  "Return the cockpit status symbol for agent-shell BUFFER."
  (cond
   ((not (buffer-live-p buffer)) 'stopped)
   ((agent-shell-cockpit--process-dead-p buffer) 'stopped)
   (t
    (pcase (ignore-errors (agent-shell-status :shell-buffer buffer))
      ('blocked 'attention)
      ('busy 'working)
      ('ready 'ready)
      ('nil 'starting)
      (_ 'unknown)))))

(defun agent-shell-cockpit--status-property (status index)
  "Return property at INDEX from STATUS' display specification."
  (nth index (assq status agent-shell-cockpit--status-spec)))

(defun agent-shell-cockpit--status-rank (status)
  "Return the sort rank for STATUS."
  (or (agent-shell-cockpit--status-property status 3) 99))

(defun agent-shell-cockpit--sorted-buffers ()
  "Return session buffers sorted by attention priority and then name."
  (sort (copy-sequence (agent-shell-cockpit--buffers))
        (lambda (a b)
          (let* ((status-a (agent-shell-cockpit--status a))
                 (status-b (agent-shell-cockpit--status b))
                 (rank-a (agent-shell-cockpit--status-rank status-a))
                 (rank-b (agent-shell-cockpit--status-rank status-b)))
            (if (= rank-a rank-b)
                (string-lessp (buffer-name a) (buffer-name b))
              (< rank-a rank-b))))))

(defun agent-shell-cockpit--clean-name (buffer)
  "Return a clean display name for BUFFER."
  (string-trim (buffer-name buffer) "\\*+" "\\*+"))

(defun agent-shell-cockpit--directory (buffer)
  "Return BUFFER's abbreviated working directory."
  (with-current-buffer buffer
    (abbreviate-file-name (or default-directory "—"))))

(defun agent-shell-cockpit--session-title (buffer)
  "Return BUFFER's non-empty agent-generated session title, or nil."
  (with-current-buffer buffer
    (when-let* ((title (and (boundp 'agent-shell--state)
                            (map-nested-elt
                             agent-shell--state '(:session :title))))
                ((stringp title))
                (title (string-trim
                        (replace-regexp-in-string "[[:space:]\n]+" " " title)))
                ((not (string-empty-p title))))
      title)))

(defun agent-shell-cockpit--status-badge (status)
  "Return a propertized badge for STATUS."
  (let ((label (agent-shell-cockpit--status-property status 1))
        (face (agent-shell-cockpit--status-property status 2)))
    (propertize (format " %-17s " (or label "[UNKNOWN]")) 'face face)))

(defun agent-shell-cockpit--insert-ascii-art ()
  "Insert the cockpit ASCII art header aligned with dashboard content."
  (dolist (line agent-shell-cockpit--ascii-art)
    (insert "  " (propertize line 'face 'agent-shell-cockpit-title) "\n")))

(defun agent-shell-cockpit--insert-heading (title face &optional count)
  "Insert section TITLE using FACE, optionally followed by COUNT."
  (insert (propertize title 'face face))
  (when count
    (insert (propertize (format "  %d" count)
                        'face 'agent-shell-cockpit-secondary)))
  (insert "\n\n"))

(defun agent-shell-cockpit--insert-row (buffer)
  "Insert one navigable row for agent-shell BUFFER."
  (let* ((status (agent-shell-cockpit--status buffer))
         (name (agent-shell-cockpit--clean-name buffer))
         (session-title (agent-shell-cockpit--session-title buffer))
         (title (or session-title name))
         (directory (agent-shell-cockpit--directory buffer))
         (details (if session-title
                      (format "%s  ·  %s" name directory)
                    directory))
         (cockpit-window (get-buffer-window (current-buffer) t))
         (available (max 12 (- (if cockpit-window
                                   (window-body-width cockpit-window)
                                 80)
                               24)))
         (start (point)))
    (insert "  " (agent-shell-cockpit--status-badge status) "  ")
    (insert (propertize
             (truncate-string-to-width title available nil nil "…")
             'face (if session-title
                       'agent-shell-cockpit-session-title
                     'default)))
    (insert "\n" (make-string 23 ?\s))
    (insert (propertize (truncate-string-to-width details available nil nil "…")
                        'face 'agent-shell-cockpit-secondary))
    (insert "\n")
    (add-text-properties
     start (point)
     (list 'agent-shell-cockpit-buffer buffer
           'mouse-face 'highlight
           'help-echo "C-j/C-k: preview; TAB or RET: enter session"))))

(defun agent-shell-cockpit--counts (buffers)
  "Return an alist of cockpit status counts for BUFFERS."
  (let (counts)
    (dolist (buffer buffers counts)
      (let ((status (agent-shell-cockpit--status buffer)))
        (setf (alist-get status counts 0) (1+ (alist-get status counts 0)))))))

(defun agent-shell-cockpit--render ()
  "Render the cockpit in the current buffer."
  (let* ((buffers (agent-shell-cockpit--sorted-buffers))
         (counts (agent-shell-cockpit--counts buffers)))
    (erase-buffer)
    (insert "\n")
    (agent-shell-cockpit--insert-ascii-art)
    (insert "\n  ")
    (insert (propertize
             (format "%d session%s  ·  %d working  ·  %d ready"
                     (length buffers) (if (= (length buffers) 1) "" "s")
                     (alist-get 'working counts 0)
                     (alist-get 'ready counts 0))
             'face 'agent-shell-cockpit-secondary))
    (insert "\n\n")

    (agent-shell-cockpit--insert-heading
     "  Sessions" 'agent-shell-cockpit-heading (length buffers))
    (if buffers
        (dolist (buffer buffers)
          (agent-shell-cockpit--insert-row buffer))
      (insert (propertize "  No sessions. Press c to create one.\n"
                          'face 'agent-shell-cockpit-secondary)))

    (insert "\n  ")
    (insert (propertize
             "C-j/k preview  ·  TAB enter  ·  c default  ·  C choose  ·  x kill  ·  q quit"
             'face 'agent-shell-cockpit-secondary))
    (insert "\n")))

(defun agent-shell-cockpit--buffer-at-point ()
  "Return the session buffer represented by the row at point."
  (get-text-property (point) 'agent-shell-cockpit-buffer))

(defun agent-shell-cockpit--goto-buffer (buffer)
  "Move point to BUFFER's row and return non-nil when found."
  (goto-char (point-min))
  (let (found)
    (while (and (not found) (not (eobp)))
      (if (eq (get-text-property (line-beginning-position)
                                 'agent-shell-cockpit-buffer)
              buffer)
          (setq found t)
        (forward-line 1)))
    found))

(defun agent-shell-cockpit--goto-first-row ()
  "Move point to the first session row, when one exists."
  (goto-char (point-min))
  (while (and (not (eobp))
              (not (agent-shell-cockpit--buffer-at-point)))
    (forward-line 1)))

(defun agent-shell-cockpit-refresh ()
  "Refresh the cockpit while preserving the selected session."
  (interactive)
  (when-let* ((buffer (and (buffer-live-p agent-shell-cockpit--buffer)
                           agent-shell-cockpit--buffer)))
    (with-current-buffer buffer
      (let* ((window (get-buffer-window buffer t))
             ;; An unselected window keeps its own point in `window-point'.
             ;; The buffer's point may meanwhile have moved elsewhere.
             (saved-point (if (window-live-p window)
                              (window-point window)
                            (point)))
             (selected-at-point
              (and (< saved-point (point-max))
                   (get-text-property
                    saved-point 'agent-shell-cockpit-buffer)))
             (selected (or selected-at-point
                           (and (buffer-live-p
                                 agent-shell-cockpit--selected-buffer)
                                agent-shell-cockpit--selected-buffer)))
             (line (line-number-at-pos saved-point))
             (inhibit-read-only t))
        (agent-shell-cockpit--render)
        (if (and selected (agent-shell-cockpit--goto-buffer selected))
            (setq agent-shell-cockpit--selected-buffer selected)
          (setq agent-shell-cockpit--selected-buffer nil)
          (goto-char (point-min))
          (forward-line (min (1- line)
                             (1- (line-number-at-pos (point-max))))))
        (when (window-live-p window)
          (set-window-point window (point)))))))

(defun agent-shell-cockpit--timer-refresh (buffer)
  "Refresh cockpit BUFFER when it is live and visible."
  (when (and (buffer-live-p buffer)
             (get-buffer-window buffer t))
    (agent-shell-cockpit-refresh)))

(defun agent-shell-cockpit--start-timer ()
  "Start the current cockpit buffer's automatic refresh timer."
  (when (timerp agent-shell-cockpit--refresh-timer)
    (cancel-timer agent-shell-cockpit--refresh-timer))
  (setq agent-shell-cockpit--refresh-timer
        (when agent-shell-cockpit-refresh-interval
          (run-with-timer agent-shell-cockpit-refresh-interval
                          agent-shell-cockpit-refresh-interval
                          #'agent-shell-cockpit--timer-refresh
                          (current-buffer)))))

(defun agent-shell-cockpit--stop-timer ()
  "Stop the current cockpit buffer's automatic refresh timer."
  (when (timerp agent-shell-cockpit--refresh-timer)
    (cancel-timer agent-shell-cockpit--refresh-timer)
    (setq agent-shell-cockpit--refresh-timer nil)))

(defun agent-shell-cockpit--navigation-current (sessions)
  "Return the session to use as the navigation origin.

Point is normally inside a row, but it can be left on a heading or other
non-row text after mouse movement or a refresh.  In that case prefer the
remembered selection and finally the first live session."
  (or (agent-shell-cockpit--buffer-at-point)
      (and (buffer-live-p agent-shell-cockpit--selected-buffer)
           (memq agent-shell-cockpit--selected-buffer sessions)
           agent-shell-cockpit--selected-buffer)
      (car sessions)))

(defun agent-shell-cockpit--move-session (step)
  "Move by STEP sessions, wrapping around the session list.

Return the selected session, or nil when there are no sessions."
  (let ((sessions (agent-shell-cockpit--sorted-buffers)))
    (if (null sessions)
        (progn
          (message "No %s session" (if (> step 0) "next" "previous"))
          nil)
      (let* ((current (agent-shell-cockpit--navigation-current sessions))
             (index (or (seq-position sessions current #'eq)
                        (if (> step 0) -1 (length sessions))))
             (target (nth (mod (+ index step) (length sessions)) sessions)))
        (agent-shell-cockpit--goto-buffer target)
        (setq agent-shell-cockpit--selected-buffer target)
        target))))

(defun agent-shell-cockpit-next ()
  "Move to the next session row, wrapping at the end."
  (interactive)
  (agent-shell-cockpit--move-session 1))

(defun agent-shell-cockpit-previous ()
  "Move to the previous session row, wrapping at the beginning."
  (interactive)
  (agent-shell-cockpit--move-session -1))

(defun agent-shell-cockpit--window-width (window)
  "Return a column width for a cockpit beside WINDOW."
  (if (integerp agent-shell-cockpit-width)
      agent-shell-cockpit-width
    (max window-min-width
         (floor (* (window-total-width window) agent-shell-cockpit-width)))))

(defun agent-shell-cockpit--put-session-right
    (session cockpit-window &optional select)
  "Show SESSION right of COCKPIT-WINDOW.
When SELECT is non-nil, select the session window."
  (unless (window-live-p cockpit-window)
    (user-error "The cockpit window is no longer live"))
  (let ((session-window
         (or (window-in-direction 'right cockpit-window)
             (split-window cockpit-window
                           (agent-shell-cockpit--window-width cockpit-window)
                           'right))))
    (set-window-buffer session-window session)
    (when select
      (select-window session-window))
    session-window))

(defun agent-shell-cockpit-preview ()
  "Preview the selected session on the right without leaving the cockpit."
  (interactive)
  (let ((session (agent-shell-cockpit--buffer-at-point))
        (cockpit-window (get-buffer-window (current-buffer) t)))
    (unless (and session (buffer-live-p session))
      (user-error "Point is not on a live session"))
    (setq agent-shell-cockpit--selected-buffer session)
    (set-window-point cockpit-window (point))
    (agent-shell-cockpit--put-session-right session cockpit-window)
    (select-window cockpit-window)))

(defun agent-shell-cockpit-preview-next ()
  "Move to and preview the next session."
  (interactive)
  (when (agent-shell-cockpit-next)
    (agent-shell-cockpit-preview)))

(defun agent-shell-cockpit-preview-previous ()
  "Move to and preview the previous session."
  (interactive)
  (when (agent-shell-cockpit-previous)
    (agent-shell-cockpit-preview)))

(defun agent-shell-cockpit-open ()
  "Open the selected session on the right, retaining the cockpit on the left."
  (interactive)
  (let ((session (agent-shell-cockpit--buffer-at-point))
        (cockpit-window (get-buffer-window (current-buffer) t)))
    (unless (and session (buffer-live-p session))
      (user-error "Point is not on a live session"))
    ;; Preserve this row before selecting another window.  Timer refreshes use
    ;; the cockpit window's point while the session has focus.
    (setq agent-shell-cockpit--selected-buffer session)
    (set-window-point cockpit-window (point))
    (agent-shell-cockpit--put-session-right session cockpit-window t)))

(defun agent-shell-cockpit-create ()
  "Create a session with the configured default agent and keep cockpit visible."
  (interactive)
  (agent-shell-cockpit--create-with-command agent-shell-cockpit-default-command))

(defun agent-shell-cockpit-create-new ()
  "Create an agent session after prompting for its ACP client."
  (interactive)
  (agent-shell-cockpit--create-with-command #'agent-shell-new-shell))

(defun agent-shell-cockpit--create-with-command (command)
  "Run interactive COMMAND and show its resulting session beside the cockpit."
  (interactive)
  (let ((before (agent-shell-cockpit--buffers))
        (cockpit (current-buffer))
        (cockpit-window (get-buffer-window (current-buffer) t)))
    (unless (commandp command)
      (user-error "Cockpit default command is not interactive: %S" command))
    (call-interactively command)
    (when-let* ((new-session
                 (seq-find (lambda (buffer) (not (memq buffer before)))
                           (agent-shell-cockpit--buffers))))
      (unless (window-live-p cockpit-window)
        (setq cockpit-window (selected-window)))
      ;; `agent-shell-new-shell' may replace the cockpit in its window.  Put
      ;; it back before placing the new session to its right.
      (set-window-buffer cockpit-window cockpit)
      (agent-shell-cockpit-refresh)
      (agent-shell-cockpit--put-session-right new-session cockpit-window t))))

(defun agent-shell-cockpit-kill ()
  "Kill the selected agent session after confirmation."
  (interactive)
  (let ((session (agent-shell-cockpit--buffer-at-point)))
    (unless (and session (buffer-live-p session))
      (user-error "Point is not on a live session"))
    (when (yes-or-no-p (format "Kill agent session %s? " (buffer-name session)))
      (let ((kill-buffer-query-functions nil))
        (kill-buffer session))
      (agent-shell-cockpit-refresh))))

(defvar-keymap agent-shell-cockpit-mode-map
  :doc "Keymap for `agent-shell-cockpit-mode'."
  "TAB" #'agent-shell-cockpit-open
  "RET" #'agent-shell-cockpit-open
  "C-j" #'agent-shell-cockpit-preview-next
  "C-k" #'agent-shell-cockpit-preview-previous
  "r" #'agent-shell-cockpit-refresh
  "c" #'agent-shell-cockpit-create
  "C" #'agent-shell-cockpit-create-new
  "x" #'agent-shell-cockpit-kill
  "n" #'agent-shell-cockpit-next
  "p" #'agent-shell-cockpit-previous
  "q" #'quit-window)

(define-derived-mode agent-shell-cockpit-mode special-mode "Agent-Cockpit"
  "Major mode for the focused `agent-shell' cockpit."
  (setq-local truncate-lines t
              cursor-type 'hbar
              buffer-read-only t
              revert-buffer-function
              (lambda (&rest _) (agent-shell-cockpit-refresh)))
  (hl-line-mode 1)
  (add-hook 'kill-buffer-hook #'agent-shell-cockpit--stop-timer nil t)
  (agent-shell-cockpit--start-timer))

;;;###autoload
(defun agent-shell-cockpit ()
  "Show the agent-shell cockpit in the selected window."
  (interactive)
  (let ((buffer (get-buffer-create agent-shell-cockpit-buffer-name)))
    (setq agent-shell-cockpit--buffer buffer)
    (switch-to-buffer buffer)
    (with-current-buffer buffer
      (unless (derived-mode-p 'agent-shell-cockpit-mode)
        (agent-shell-cockpit-mode))
      (let ((inhibit-read-only t))
        (agent-shell-cockpit--render))
      (agent-shell-cockpit--goto-first-row))))

(provide 'agent-shell-cockpit)

;;; agent-shell-cockpit.el ends here
