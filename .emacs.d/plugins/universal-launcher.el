;;; universal-launcher.el --- Consult launcher for the desktop  -*- lexical-binding: t; -*-

;;; Commentary:
;; A small, local-first launcher inspired by consult-omni and Alfred-style
;; Emacs launchers.  It combines desktop applications, i3 windows, Emacs
;; resources, web searches, and common capture commands in one Consult prompt.

;;; Code:

(require 'cl-lib)
(require 'consult)
(require 'json)
(require 'org-element)
(require 'recentf)
(require 'seq)
(require 'subr-x)
(require 'url-util)

(recentf-mode 1)

(defgroup universal-launcher nil
  "Launch desktop and Emacs resources with Consult."
  :group 'convenience)

(defcustom universal-launcher-bookmarks-file "~/org/bookmarks.org"
  "Org file containing web bookmarks."
  :type 'file
  :group 'universal-launcher)

(defcustom universal-launcher-default-search-engine "Google"
  "Search engine used for free-form launcher input."
  :type 'string
  :group 'universal-launcher)

(defcustom universal-launcher-browser-class-regexp
  "(?i)google-chrome|chromium|firefox"
  "i3 class regexp used by the Focus browser action."
  :type 'string
  :group 'universal-launcher)

(defconst universal-launcher--search-engines
  '(("Google" . "https://www.google.com/search?q=")
    ("Erlang" . "https://www.erlang.org/doc/search.html?v=29&q=")
    ("Elixir" . "https://hexdocs.pm/?packages=elixir%3A1.20.4%2Ceex%3A1.20.4%2Cex_unit%3A1.20.4%2Ciex%3A1.20.4%2Clogger%3A1.20.4%2Cmix%3A1.20.4&q=")
    ("Google Calender" . "https://calendar.google.com/calendar/u/0/r/search?q=")
    ("Nix Packages" . "https://search.nixos.org/packages?channel=25.11&query=")
    ("GitHub" . "https://github.com/search?q=")
    ("Google Maps" . "https://www.google.com/maps/search/")
    ("Rust Docs" . "https://doc.rust-lang.org/std/?search=")
    ("Reddit" . "https://www.reddit.com/search/?q="))
  "Search engines offered by the launcher.")

(defvar universal-launcher-context-frame nil
  "Ordinary Emacs frame that was selected before opening the launcher.")

(unless (assoc-string universal-launcher-default-search-engine
                      universal-launcher--search-engines)
  (setq universal-launcher-default-search-engine "Google"))

(defun universal-launcher--open-url (url)
  "Open URL with the configured Emacs browser integration."
  (browse-url url))

(defun universal-launcher--search (query &optional engine-url)
  "Search for QUERY with ENGINE-URL or the configured default engine."
  (let ((base (or engine-url
                  (alist-get universal-launcher-default-search-engine
                             universal-launcher--search-engines
                             nil nil #'string=)
                  (alist-get "Google" universal-launcher--search-engines
                             nil nil #'string=))))
    (universal-launcher--open-url
     (if (string-match-p "\\`\\(?:https?://\\|www\\.\\)" query)
         (if (string-prefix-p "www." query) (concat "https://" query) query)
       (concat base (url-hexify-string query))))))

(defun universal-launcher--strip-desktop-field-codes (exec-string)
  "Remove freedesktop field codes from desktop EXEC-STRING."
  (let ((placeholder "__UNIVERSAL_LAUNCHER_PERCENT__"))
    (string-trim
     (replace-regexp-in-string
      placeholder "%"
      (replace-regexp-in-string
       "%[fFuUdDnNickvm]" ""
       (replace-regexp-in-string "%%" placeholder exec-string t t)
       t t)
      t t))))

(defun universal-launcher--run-application (exec-string)
  "Start the application described by desktop EXEC-STRING without a shell."
  (let* ((clean (universal-launcher--strip-desktop-field-codes exec-string))
         (parts (split-string-and-unquote clean))
         (program (car parts)))
    (if (and program (executable-find program))
        (apply #'start-process program nil program (cdr parts))
      (user-error "Application executable not found: %s" (or program clean)))))

(defun universal-launcher--run-command (command)
  "Run COMMAND in the background through the user's shell."
  (start-process-shell-command "universal-launcher-command" nil command))

(defun universal-launcher--desktop-entry (file)
  "Return a visible application pair parsed from desktop entry FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward "^\\[Desktop Entry\\]" nil t)
      (let ((end (save-excursion
                   (if (re-search-forward "^\\[Desktop Action" nil t)
                       (match-beginning 0)
                     (point-max))))
            name exec type no-display hidden try-exec)
        (while (re-search-forward
                "^\\([A-Za-z0-9-]+\\)[[:space:]]*=[[:space:]]*\\(.*\\)$"
                end t)
          (pcase (match-string 1)
            ("Name" (unless name (setq name (match-string 2))))
            ("Exec" (unless exec (setq exec (match-string 2))))
            ("TryExec" (setq try-exec (match-string 2)))
            ("Type" (setq type (match-string 2)))
            ("NoDisplay" (setq no-display (string= (downcase (match-string 2)) "true")))
            ("Hidden" (setq hidden (string= (downcase (match-string 2)) "true")))))
        (when (and name exec (equal type "Application")
                   (not no-display) (not hidden)
                   (or (not try-exec) (executable-find try-exec)))
          (cons name exec))))))

(defun universal-launcher--applications ()
  "Return applications found in system and user desktop directories."
  (let ((dirs '("/usr/share/applications/"
                "/usr/local/share/applications/"
                "~/.local/share/applications/"
                "~/.nix-profile/share/applications/"
                "/run/current-system/profile/share/applications/"))
        applications)
    (dolist (dir dirs)
      (setq dir (expand-file-name dir))
      (when (file-directory-p dir)
        (dolist (file (directory-files dir t "\\.desktop\\'"))
          (when-let* ((entry (universal-launcher--desktop-entry file)))
            (push entry applications)))))
    (sort (cl-delete-duplicates applications
                                :key #'car :test #'string= :from-end t)
          (lambda (a b) (string-lessp (car a) (car b))))))

(defun universal-launcher--walk-i3-tree (node)
  "Return window candidates found below i3 tree NODE."
  (let* ((id (alist-get 'id node))
         (type (alist-get 'type node))
         (name (alist-get 'name node))
         (properties (alist-get 'window_properties node))
         (class (or (alist-get 'class properties)
                    (alist-get 'instance properties)))
         windows)
    (when (and id name class (equal type "con")
               (not (string-match-p "\\`emacs-\\(?:launcher\\|capture\\)\\'"
                                    (downcase name))))
      (push (cons (format "%s (%s)" name class) id) windows))
    (dolist (child (append (alist-get 'nodes node)
                           (alist-get 'floating_nodes node)))
      (setq windows
            (nconc windows (universal-launcher--walk-i3-tree child))))
    windows))

(defun universal-launcher--windows ()
  "Return visible i3 windows."
  (when (executable-find "i3-msg")
    (with-temp-buffer
      (when (= 0 (call-process "i3-msg" nil t nil "-t" "get_tree"))
        (goto-char (point-min))
        (condition-case nil
            (sort
             (universal-launcher--walk-i3-tree
              (json-parse-buffer :object-type 'alist
                                 :array-type 'list
                                 :null-object nil
                                 :false-object nil))
             (lambda (a b) (string-lessp (car a) (car b))))
          (error nil))))))

(defun universal-launcher--focus-window (con-id)
  "Focus the i3 container identified by CON-ID."
  (call-process "i3-msg" nil nil nil (format "[con_id=%s] focus" con-id)))

(defun universal-launcher--buffers ()
  "Return ordinary Emacs buffers."
  (cl-loop for buffer in (buffer-list)
           for name = (buffer-name buffer)
           unless (string-prefix-p " " name)
           collect (cons name buffer)))

(defun universal-launcher--show-buffer (buffer)
  "Show BUFFER in the Emacs frame that preceded the launcher."
  (let ((frame (if (frame-live-p universal-launcher-context-frame)
                 universal-launcher-context-frame
                 (seq-find (lambda (candidate)
                             (and (display-graphic-p candidate)
                                  (not (eq (frame-parameter candidate 'minibuffer)
                                           'only))))
                           (frame-list)))))
    (unless frame
      (setq frame (make-frame)))
    (with-selected-frame frame
      (switch-to-buffer buffer))
    (select-frame-set-input-focus frame)))

(defun universal-launcher--files ()
  "Return recent files that still exist."
  (cl-loop for file in recentf-list
           when (file-exists-p file)
           collect (cons (abbreviate-file-name file) file)))

(defun universal-launcher--show-file (file)
  "Visit FILE in the Emacs frame that preceded the launcher."
  (universal-launcher--show-buffer (find-file-noselect file)))

(defun universal-launcher--bookmarks ()
  "Return HTTP bookmarks parsed from `universal-launcher-bookmarks-file'."
  (let ((file (expand-file-name universal-launcher-bookmarks-file))
        bookmarks)
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (delay-mode-hooks (org-mode))
        (org-element-map (org-element-parse-buffer) 'link
          (lambda (link)
            (when (member (org-element-property :type link) '("http" "https"))
              (let* ((url (org-element-property :raw-link link))
                     (description
                      (string-trim
                       (org-element-interpret-data
                        (org-element-contents link)))))
                (push (cons (if (string-empty-p description) url description)
                            url)
                      bookmarks)))))))
    (sort (cl-delete-duplicates bookmarks
                                :key #'cdr :test #'string= :from-end t)
          (lambda (a b) (string-lessp (car a) (car b))))))

(defun universal-launcher--commands ()
  "Return executable command names from PATH."
  (let (commands)
    (dolist (dir (parse-colon-path (getenv "PATH")))
      (when (file-directory-p dir)
        (dolist (file (directory-files dir t directory-files-no-dot-files-regexp))
          (when (and (file-executable-p file) (not (file-directory-p file)))
            (push (file-name-nondirectory file) commands)))))
    (sort (delete-dups commands) #'string-lessp)))

(defun universal-launcher--browser-actions ()
  "Return common browser actions."
  '(("Focus browser" . focus)
    ("New browser tab" . new-tab)))

(defun universal-launcher--browser-action (action)
  "Perform browser ACTION."
  (pcase action
    ('focus
     (call-process "i3-msg" nil nil nil
                   (format "[class=\"%s\"] focus"
                           universal-launcher-browser-class-regexp)))
    ('new-tab (universal-launcher--open-url "about:blank"))))

(defun universal-launcher--search-engines ()
  "Return configured search engines as Consult candidates."
  universal-launcher--search-engines)

(defun universal-launcher--search-with-engine (engine-url)
  "Prompt for a query and search using ENGINE-URL."
  (universal-launcher--search (read-string "Search: ") engine-url))

(defun universal-launcher--emacs-actions ()
  "Return common popup and capture actions."
  '(("Capture to Org inbox" . obp/desktop-org-capture)
    ("Capture Org-roam note" . obp/desktop-org-roam-capture)
    ("Capture today's Org-roam daily" . obp/desktop-org-roam-daily-capture)))

(defun universal-launcher--run-emacs-action (function)
  "Run interactive FUNCTION after the launcher has closed."
  (run-at-time 0 nil function))

(defun universal-launcher--sources ()
  "Return the Consult sources used by the launcher."
  '((:name "Applications" :narrow ?a :category application
     :items universal-launcher--applications
     :action universal-launcher--run-application
     :disposition close)
    (:name "Windows" :narrow ?w :category window
     :items universal-launcher--windows
     :action universal-launcher--focus-window
     :disposition close)
    (:name "Buffers" :narrow ?b :category buffer
     :items universal-launcher--buffers
     :action universal-launcher--show-buffer
     :disposition context)
    (:name "Files" :narrow ?f :category file
     :items universal-launcher--files
     :action universal-launcher--show-file
     :disposition context)
    (:name "Bookmarks" :narrow ?k :category bookmark
     :items universal-launcher--bookmarks
     :action universal-launcher--open-url
     :disposition close)
    (:name "Emacs" :narrow ?e :category command
     :items universal-launcher--emacs-actions
     :action universal-launcher--run-emacs-action
     :disposition close)
    (:name "Browser" :narrow ?g :category browser
     :items universal-launcher--browser-actions
     :action universal-launcher--browser-action
     :disposition close)
    (:name "Search" :narrow ?s :category web-search :default t
     :items universal-launcher--search-engines
     :action universal-launcher--search-with-engine
     :new universal-launcher--search
     :disposition close)
    (:name "Command" :narrow ?c :category command
     :items universal-launcher--commands
     :action universal-launcher--run-command
     :new universal-launcher--run-command
     :disposition close)))

;;;###autoload
(defun universal-launcher-popup (&optional context-frame)
  "Select and execute an action from the universal launcher.
CONTEXT-FRAME is used when a selected Emacs resource needs a normal frame."
  (interactive)
  (let ((universal-launcher-context-frame
         (or context-frame universal-launcher-context-frame)))
    (when-let* ((selected
                 (consult--multi (universal-launcher--sources)
                                 :prompt "Launch: "
                                 :require-match nil
                                 :sort nil
                                 :history 'universal-launcher-history)))
      (or (plist-get (cdr selected) :disposition) 'close))))

(provide 'universal-launcher)
;;; universal-launcher.el ends here
