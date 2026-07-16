;;; agenda-prs.el --- Rich Headline GitHub PR Sync -*- lexical-binding: t; -*-

(require 'json)
(require 'org)

(defgroup agenda-prs nil
  "Settings for synchronizing GitHub PRs into Org Mode."
  :group 'org
  :prefix "agenda-prs-")

;;; --- Configurable Variables (Set these in host.el) ---

(defcustom agenda-prs-github-user "your_username"
  "Your GitHub username, used for PR state logic."
  :type 'string)

(defcustom agenda-prs-label "label"
  "The GitHub label to search for."
  :type 'string)

(defcustom agenda-prs-target-file "~/notes/work/data/reviews.org"
  "The absolute path to the Org file where PRs should be synced."
  :type 'string)

(defcustom agenda-prs-closed-state "MERGED"
  "The TODO state for PRs no longer returned by the search (overrides IDC)."
  :type 'string)

;;; --- Core Logic ---

(defun agenda-prs--fetch-data ()
  "Fetch PRs via `gh` CLI and return a hash table of parsed data."
  (let* ((graphql-query
          (format "query($q: String!) { search(query: $q, type: ISSUE, first: 30) { nodes { ... on PullRequest { title url isDraft author { login } repository { name } reviews(first: 1, states: APPROVED, author: \"%s\") { totalCount } } } } }"
                  agenda-prs-github-user))
         (q-string (format "is:pr is:open label:%s" agenda-prs-label))
         (json-string
          (with-temp-buffer
            (call-process "gh" nil t nil "api" "graphql"
                          "-f" (concat "query=" graphql-query)
                          "-f" (concat "q=" q-string))
            (buffer-string)))
         (parsed (json-parse-string json-string :object-type 'hash-table :array-type 'list))
         (nodes (gethash "nodes" (gethash "search" (gethash "data" parsed))))
         (prs (make-hash-table :test 'equal)))

    (dolist (node nodes)
      (when (gethash "url" node)
        (let* ((url (gethash "url" node))
               (title (gethash "title" node))
               (author (gethash "login" (gethash "author" node)))
               (repo (gethash "name" (gethash "repository" node)))
               (is-draft (eq (gethash "isDraft" node) t))
               (reviews-count (gethash "totalCount" (gethash "reviews" node)))
               (approved (> reviews-count 0))
               (is-mine (string= author agenda-prs-github-user)))

          ;; Mimic bash filter: skip drafts unless you are the author
          (when (or (not is-draft) is-mine)
            (puthash url (list :title title :author author :repo repo
                               :is-draft is-draft :approved approved :is-mine is-mine)
                     prs)))))
    prs))

(defun agenda-prs--determine-state (data)
  "Determine the correct TODO keyword based on the PR's status."
  (let ((is-mine (plist-get data :is-mine))
        (is-draft (plist-get data :is-draft))
        (approved (plist-get data :approved)))
    (cond
     ((and is-mine is-draft) "DRAFT")
     (is-mine "AWAITING")
     (approved "APPROVED")
     (t "REVIEW"))))

(defun agenda-prs--format-title (url data)
  "Generate the string for the agenda headline (no emojis)."
  ;; Format: [[URL][Title]] (Author - Repo)
  (format "[[%s][%s]] (%s - %s)"
          url (plist-get data :title)
          (plist-get data :author) (plist-get data :repo)))

(defun agenda-prs--sync-buffer (fetched-prs)
  "Safely update existing PRs and insert new ones."
  (let ((seen-urls (make-hash-table :test 'equal)))

    ;; Pass 1: Update existing headings and close missing ones
    (org-map-entries
     (lambda ()
       ;; org-get-heading t t t t strips TODOs, tags, priorities, etc., leaving just the title text
       (let* ((heading (org-get-heading t t t t))
              ;; Extract the URL from the [[URL][Title]] link format
              (url (when (and heading (string-match "\\[\\[\\(.*?\\)\\]\\[" heading))
                     (match-string 1 heading)))
              (current-todo (org-get-todo-state)))
         (when url
           (let ((data (gethash url fetched-prs)))
             (if data
                 ;; PR exists and is active: Track it and update text/state
                 (progn
                   (puthash url t seen-urls)
                   (let ((target-todo (agenda-prs--determine-state data)))
                     ;; Update the state UNLESS it is marked as IDC
                     (unless (string= current-todo "IDC")
                       (unless (string= current-todo target-todo)
                         (org-todo target-todo))))
                   ;; Update the headline text in case the title changed
                   (org-back-to-heading t)
                   (when (looking-at org-complex-heading-regexp)
                     (replace-match (agenda-prs--format-title url data) t t nil 4)))

               ;; PR is missing from fetch: Close it (this overrides IDC)
               (unless (string= current-todo agenda-prs-closed-state)
                 (org-todo agenda-prs-closed-state)))))))
     t)

    ;; Pass 2: Insert new PRs at the end of the file
    (goto-char (point-max))
    (maphash
     (lambda (url data)
       (unless (gethash url seen-urls)
         (unless (bolp) (insert "\n"))
         (let ((initial-todo (agenda-prs--determine-state data)))
           (insert (format "** %s %s\n"
                           initial-todo
                           (agenda-prs--format-title url data))))))
     fetched-prs)))

;;; --- Main Commands ---

(defun obp/refresh-prs-agenda ()
  "Fetch fresh PR data and update the Org file."
  (interactive)
  (save-window-excursion
    (let ((fetched-prs (agenda-prs--fetch-data))
          (reviews-file (expand-file-name agenda-prs-target-file)))
      (with-current-buffer (find-file-noselect reviews-file)
        (save-excursion
          (agenda-prs--sync-buffer fetched-prs))
        (save-buffer)))))

(defun obp/agenda-refresh-and-redraw ()
  "Fetch fresh data and update the active agenda buffer view."
  (interactive)
  (obp/refresh-prs-agenda)
  (when (eq major-mode 'org-agenda-mode)
    (org-agenda-redo))
  (message "PR Dashboard updated!"))

(provide 'agenda-prs)
;;; agenda-prs.el ends here
