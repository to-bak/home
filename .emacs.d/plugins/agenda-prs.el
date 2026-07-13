(defgroup agenda-prs nil
  "Settings for synchronizing GitHub PRs into Org Mode."
  :group 'org
  :prefix "agenda-prs-")

(defcustom agenda-prs-script-cmd "~/software/tooling/my_reviews"
  "The shell command used to fetch PR data."
  :type 'string
  :group 'agenda-prs)

(defcustom agenda-prs-target-file "~/notes/work/data/reviews.org"
  "The absolute path to the Org file where PRs should be synced."
  :type 'string
  :group 'agenda-prs)

(defcustom agenda-prs-closed-state "CLOSED"
  "The TODO state to assign to PRs that are no longer returned by the script."
  :type 'string
  :group 'agenda-prs)

;;; --- Internal Helper Functions ---

(defun agenda-prs--fetch-and-parse ()
  "Execute the script command and return a hash table of PR URLs to Org lines."
  (let* ((output (shell-command-to-string agenda-prs-script-cmd))
         (lines (split-string output "\n" t))
         (fetched-urls (make-hash-table :test 'equal)))
    (dolist (line lines)
      (when (string-match "\\[\\[\\([^]]+\\)\\]\\[" line)
        (puthash (match-string 1 line) line fetched-urls)))
    fetched-urls))

(defun agenda-prs--insert-new (fetched-urls)
  "Insert PRs from FETCHED-URLS that do not already exist in the current buffer."
  (maphash
   (lambda (url line)
     (goto-char (point-min))
     ;; If the exact URL is missing, register the headline entry
     (unless (re-search-forward (regexp-quote url) nil t)
       (goto-char (point-max))
       (unless (bolp) (insert "\n"))
       (insert line "\n")
       ;; Step backward into the newly populated entry to bind metadata
       (save-excursion
         (forward-line -1)
         (org-set-property "PR_URL" url))))
   fetched-urls))

(defun agenda-prs--close-stale (fetched-urls)
  "Mark PRs as closed if their `PR_URL` is not in FETCHED-URLS."
  (org-map-entries
   (lambda ()
     (let ((url (org-entry-get (point) "PR_URL"))
           (state (org-get-todo-state)))
       ;; Check: Has URL? Not in fetched list? Not already closed?
       (when (and url
                  (not (gethash url fetched-urls))
                  (not (member state org-done-keywords)))
         (org-todo agenda-prs-closed-state))))
   t))

;;; --- Main Interactive Commands ---

(defun obp/refresh-prs-agenda ()
  "Fetch fresh PR data and safely synchronize it with the target Org file.
New PRs are added, and missing PRs are marked as closed."
  (interactive)
  (save-window-excursion
    (let ((fetched-urls (agenda-prs--fetch-and-parse))
          (reviews-file (expand-file-name agenda-prs-target-file)))

      (with-current-buffer (find-file-noselect reviews-file)
        (save-excursion
          (agenda-prs--insert-new fetched-urls)
          (agenda-prs--close-stale fetched-urls))
        (save-buffer)))))

(defun obp/agenda-refresh-and-redraw ()
  "Fetch fresh data and update the active agenda buffer view.
   If NO-REDO is non-nil, skip calling `org-agenda-redo`."
  (interactive)
  (obp/refresh-prs-agenda)
  (org-agenda-redo)
  (message "Dashboard updated with fresh data!"))

(provide 'agenda-prs)
;;; agenda-prs.el ends here
