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

(defun obp/refresh-prs-agenda ()
  "Fetch fresh PR data and safely synchronize it with the target Org file."
  (interactive)
  (save-window-excursion
    (let* ((cmd agenda-prs-script-cmd)
           (output (shell-command-to-string cmd))
           (lines (split-string output "\n" t))
           (fetched-urls (make-hash-table :test 'equal))
           (reviews-file (expand-file-name agenda-prs-target-file)))

      ;; 1. Parse the Org-formatted lines to extract the raw URL
      (dolist (line lines)
        (when (string-match "\\[\\[\\([^]]+\\)\\]\\[" line)
          (puthash (match-string 1 line) line fetched-urls)))

      (with-current-buffer (find-file-noselect reviews-file)
        (save-excursion
          ;; 2. Process New PRs securely
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
