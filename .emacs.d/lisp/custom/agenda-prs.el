;;; agenda-prs.el --- Asynchronous GitHub PR agenda sync -*- lexical-binding: t; -*-

(require 'org)
(require 'cl-lib)
(require 'json)
(require 'subr-x)

(defgroup agenda-prs nil
  "Synchronize labeled GitHub pull requests into an Org file."
  :group 'org :prefix "agenda-prs-")

(defcustom agenda-prs-github-user nil
  "GitHub login whose PRs and approvals are tracked."
  :type '(choice (const nil) string))
(defcustom agenda-prs-label nil
  "Label selecting open pull requests."
  :type '(choice (const nil) string))
(defcustom agenda-prs-target-file "~/notes/work/data/reviews.org"
  "Org file containing synchronized PR headings."
  :type 'file)
(defcustom agenda-prs-refresh-interval 600
  "Seconds between automatic refreshes. Restart the mode after changing this."
  :type 'natnum)
(defcustom agenda-prs-closed-state "CLOSED"
  "State for PRs no longer matching the open-PR search.
Disappearance does not distinguish merged, closed or relabeled PRs."
  :type 'string)

(defvar agenda-prs--process nil)
(defvar agenda-prs--timer nil)

(defun agenda-prs-configured-p ()
  "Return non-nil when usable account and label settings are present."
  (and (stringp agenda-prs-github-user)
       (string-match-p "\\`[[:alnum:]][[:alnum:]-]*\\'" agenda-prs-github-user)
       (not (equal agenda-prs-github-user "your_username"))
       (stringp agenda-prs-label) (not (string-empty-p agenda-prs-label))
       (executable-find "gh")))

(defun agenda-prs--parse (buffer user)
  "Validate every response page in BUFFER and return PR data for USER."
  (with-current-buffer buffer
    (goto-char (point-min))
    (let ((pages (json-parse-buffer :object-type 'hash-table :array-type 'list
                                    :false-object nil :null-object nil))
          (prs (make-hash-table :test 'equal))
          (count 0) total last-info)
      (unless (and (listp pages) pages) (error "Missing GitHub response pages"))
      (dolist (page pages)
        (when (gethash "errors" page) (error "GitHub returned GraphQL errors"))
        (let* ((data (gethash "data" page))
               (search (and (hash-table-p data) (gethash "search" data))))
          (unless (hash-table-p search) (error "Missing GitHub search results"))
          (setq total (gethash "issueCount" search)
                last-info (gethash "pageInfo" search))
          (unless (and (numberp total) (<= total 1000) (hash-table-p last-info))
            (error "Search exceeds GitHub's result limit or is incomplete"))
          (dolist (node (gethash "nodes" search))
            (let* ((url (gethash "url" node))
                   (author (gethash "login" (gethash "author" node)))
                   (repo (gethash "name" (gethash "repository" node)))
                   (reviews (gethash "totalCount" (gethash "reviews" node)))
                   (draft (gethash "isDraft" node)))
              (unless (and (stringp url) (stringp author) (stringp repo)
                           (stringp (gethash "title" node)) (numberp reviews))
                (error "Incomplete PR data"))
              (cl-incf count)
              (puthash url
                       (list :title (gethash "title" node) :author author :repo repo
                             :is-draft draft :is-mine (string-equal (downcase author) (downcase user))
                             :approved (> reviews 0)) prs)))))
      (unless (and (= count total) (not (gethash "hasNextPage" last-info)))
        (error "Incomplete PR pagination; preserving existing entries"))
      prs)))

(defun agenda-prs--determine-state (data)
  "Return the TODO keyword corresponding to PR DATA."
  (cond ((and (plist-get data :is-mine) (plist-get data :is-draft)) "DRAFT")
        ((plist-get data :is-mine) "AWAITING")
        ((plist-get data :approved) "APPROVED")
        (t "REVIEW")))

(defun agenda-prs--format-title (url data)
  "Return the Org headline text for URL and DATA."
  (format "%s (%s - %s)"
          (org-link-make-string url (replace-regexp-in-string
                                     "[\n\r]+" " " (plist-get data :title)))
          (plist-get data :author) (plist-get data :repo)))

(defun agenda-prs--sync-buffer (prs)
  "Update tracked PRs from complete PRS data, preserving user annotations."
  (let ((seen (make-hash-table :test 'equal))
        (org-inhibit-logging t)
        (org-log-done nil))
    (org-map-entries
     (lambda ()
       (let* ((heading (org-get-heading t t t t))
              (url (or (org-entry-get nil "PR_URL")
                       (when (string-match
                              "\\[\\[\\(https://github\\.com/[^/]+/[^/]+/pull/[0-9]+\\)\\]" heading)
                         (match-string 1 heading))))
              (state (org-get-todo-state))
              (data (and url (gethash url prs))))
         (when url
           (puthash url t seen)
           (if data
               (progn
                 (unless (equal state "IDC")
                   (let ((next (agenda-prs--determine-state data)))
                     (unless (equal state next) (org-todo next))))
                 (let ((title (agenda-prs--format-title url data)))
                   (unless (equal heading title) (org-edit-headline title))))
             (unless (equal state agenda-prs-closed-state)
               (org-todo agenda-prs-closed-state))))))
     nil)
    (goto-char (point-max))
    (maphash
     (lambda (url data)
       ;; Retain old behavior: other authors' drafts are not inserted.
       (unless (or (gethash url seen)
                   (and (plist-get data :is-draft) (not (plist-get data :is-mine))))
         (unless (bolp) (insert "\n"))
         (insert (format "** %s %s\n" (agenda-prs--determine-state data)
                         (agenda-prs--format-title url data)))))
     prs)))

(defun agenda-prs--apply (prs file)
  "Apply validated PRS to FILE without saving unrelated user edits."
  (make-directory (file-name-directory file) t)
  (with-current-buffer (find-file-noselect file)
    (when (buffer-modified-p)
      (error "PR file has unsaved edits; skipping this refresh"))
    (unless (verify-visited-file-modtime (current-buffer))
      (revert-buffer t t))
    (save-excursion
      (save-restriction
        (widen)
        (atomic-change-group (agenda-prs--sync-buffer prs))))
    (when (buffer-modified-p) (save-buffer)))
  ;; Redraw only displayed agendas, preserving the user's selected window.
  (when (fboundp 'org-agenda-redo)
    (save-selected-window
      (dolist (buffer (buffer-list))
        (when-let* ((window (get-buffer-window buffer t))
                    ((with-current-buffer buffer (derived-mode-p 'org-agenda-mode))))
          (with-selected-window window (org-agenda-redo t)))))))

(defun agenda-prs--finish (process _event)
  "Handle completion of asynchronous PROCESS and release its buffers."
  (when (memq (process-status process) '(exit signal))
    (unwind-protect
        (unless (process-get process 'cancelled)
          (condition-case err
              (progn
                (unless (= (process-exit-status process) 0)
                  (error "GitHub CLI failed (exit %d); keeping existing PRs"
                         (process-exit-status process)))
                (agenda-prs--apply
                 (agenda-prs--parse (process-buffer process) (process-get process 'user))
                 (process-get process 'file))
                (message "PR agenda refreshed"))
            (error (message "PR agenda: %s" (error-message-string err)))))
      (when-let* ((timer (process-get process 'timeout))) (cancel-timer timer))
      (when (eq process agenda-prs--process) (setq agenda-prs--process nil))
      (dolist (buffer (list (process-buffer process) (process-get process 'stderr)))
        (when (buffer-live-p buffer) (kill-buffer buffer))))))

(defun obp/refresh-prs-agenda ()
  "Start an asynchronous PR refresh, reusing any request already running."
  (interactive)
  (unless (agenda-prs-configured-p)
    (user-error "Configure agenda-prs-github-user and agenda-prs-label, and install gh"))
  (unless (process-live-p agenda-prs--process)
    (let* ((output (generate-new-buffer " *agenda-prs-output*"))
           (stderr (generate-new-buffer " *agenda-prs-errors*"))
           (query (concat
                   "query($q:String!,$user:String!,$endCursor:String){"
                   "search(query:$q,type:ISSUE,first:100,after:$endCursor){"
                   "issueCount pageInfo{hasNextPage endCursor} nodes{... on PullRequest{"
                   "title url isDraft author{login} repository{name} "
                   "reviews(first:1,states:APPROVED,author:$user){totalCount}}}}}")))
      (condition-case err
          (progn
            (setq agenda-prs--process
                  (make-process
                   :name "agenda-prs" :buffer output :stderr stderr :noquery t
                   :connection-type 'pipe :sentinel #'ignore
                   :command (list "gh" "api" "graphql" "--paginate" "--slurp"
                                  "-f" (concat "query=" query)
                                  "-f" (concat "user=" agenda-prs-github-user)
                                  "-f" (concat "q=is:pr is:open label:"
                                               (json-serialize agenda-prs-label)))))
            (process-put agenda-prs--process 'user agenda-prs-github-user)
            (process-put agenda-prs--process 'file (expand-file-name agenda-prs-target-file))
            (process-put agenda-prs--process 'stderr stderr)
            (process-put agenda-prs--process 'timeout
                         (run-at-time 90 nil
                                      (lambda (process)
                                        (when (process-live-p process) (delete-process process)))
                                      agenda-prs--process))
            (set-process-sentinel agenda-prs--process #'agenda-prs--finish)
            (when (memq (process-status agenda-prs--process) '(exit signal))
              (agenda-prs--finish agenda-prs--process "finished")))
        (error (kill-buffer output) (kill-buffer stderr)
               (signal (car err) (cdr err))))))
  agenda-prs--process)

(defun obp/agenda-refresh-and-redraw ()
  "Redraw the agenda now and refresh PRs asynchronously."
  (interactive)
  (when (derived-mode-p 'org-agenda-mode) (org-agenda-redo))
  (obp/refresh-prs-agenda))

(defun agenda-prs--refresh ()
  "Timer entry point; report errors without interrupting editing."
  (condition-case err (obp/refresh-prs-agenda)
    (error (message "PR agenda: %s" (error-message-string err)))))

(define-minor-mode agenda-prs-auto-refresh-mode
  "Refresh PR data periodically in a background process."
  :global t :lighter nil
  (when agenda-prs--timer (cancel-timer agenda-prs--timer))
  (setq agenda-prs--timer nil)
  (if agenda-prs-auto-refresh-mode
      (if (and (agenda-prs-configured-p) (> agenda-prs-refresh-interval 0))
          (setq agenda-prs--timer
                (run-at-time 5 agenda-prs-refresh-interval #'agenda-prs--refresh))
        (setq agenda-prs-auto-refresh-mode nil)
        (user-error "Configure PR account, label and a positive refresh interval"))
    (when (process-live-p agenda-prs--process)
      (process-put agenda-prs--process 'cancelled t)
      (delete-process agenda-prs--process))))

(provide 'agenda-prs)
;;; agenda-prs.el ends here
