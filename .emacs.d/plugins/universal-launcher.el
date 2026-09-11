;;; universal-launcher.el --- Consult launcher for Sway  -*- lexical-binding: t; -*-

;;; Commentary:
;; A small multi-source launcher for native Wayland applications and common
;; Emacs resources.  Consult supplies source headings and narrowing.

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
  "Launch applications and resources with Consult."
  :group 'convenience)

(defcustom universal-launcher-bookmarks-file "~/org/bookmarks.org"
  "Org file containing web bookmarks."
  :type 'file
  :group 'universal-launcher)

(defcustom universal-launcher-default-search-engine "Google"
  "Search engine used for free-form launcher input."
  :type 'string
  :group 'universal-launcher)

(defconst universal-launcher--search-engines
  '(("Google" . "https://www.google.com/search?q=")
    ("Reddit" . "https://www.reddit.com/search/?q=")
    ("Nix Packages" . "https://search.nixos.org/packages?channel=25.05&query=")
    ("NixOS Options" . "https://search.nixos.org/options?channel=25.05&query=")
    ("GitHub" . "https://github.com/search?q=")
    ("Google Maps" . "https://www.google.com/maps/search/")
    ("Rust Docs" . "https://doc.rust-lang.org/std/?search=")
    ("MELPA" . "https://melpa.org/#/?q=")
    ("Emacs Docs" . "https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html?search="))
  "Search engines offered by the launcher.")

(unless (assoc-string universal-launcher-default-search-engine
                      universal-launcher--search-engines)
  (setq universal-launcher-default-search-engine "Google"))

(defun universal-launcher--chrome-program ()
  "Return the installed Google Chrome executable."
  (or (executable-find "google-chrome-stable")
      (executable-find "google-chrome")))

(defun universal-launcher--open-url (url)
  "Open URL in Google Chrome."
  (when-let* ((chrome (universal-launcher--chrome-program)))
    (start-process "google-chrome" nil chrome "--new-tab" url)))

(defun universal-launcher--search (query &optional engine-url)
  "Search for QUERY with ENGINE-URL or the configured default engine."
  (let ((base (or engine-url
                  (alist-get universal-launcher-default-search-engine
                             universal-launcher--search-engines
                             nil nil #'string=)
                  (alist-get "Google" universal-launcher--search-engines
                             nil nil #'string=))))
    (if (string-match-p "\\`\\(?:https?://\\|www\\.\\)" query)
        (universal-launcher--open-url
         (if (string-prefix-p "www." query) (concat "https://" query) query))
      (universal-launcher--open-url
       (concat base (url-hexify-string query))))))

(defun universal-launcher--run-application (exec-string)
  "Start the application described by desktop EXEC-STRING."
  (let* ((parts (split-string-and-unquote exec-string))
         (program (car parts)))
    (when program
      (apply #'start-process program nil program (cdr parts)))))

(defun universal-launcher--run-command (command)
  "Run shell COMMAND verbatim in the background."
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
            name exec type no-display hidden)
        (while (re-search-forward
                "^\\([A-Za-z0-9-]+\\)[[:space:]]*=[[:space:]]*\\(.*\\)$"
                end t)
          (pcase (match-string 1)
            ("Name" (unless name (setq name (match-string 2))))
            ("Exec" (unless exec (setq exec (match-string 2))))
            ("Type" (setq type (match-string 2)))
            ("NoDisplay" (setq no-display (string= (match-string 2) "true")))
            ("Hidden" (setq hidden (string= (match-string 2) "true")))))
        (when (and name exec (equal type "Application")
                   (not no-display) (not hidden))
          (cons name
                (string-trim
                 (replace-regexp-in-string "%[A-Za-z]" "" exec))))))))

(defun universal-launcher--applications ()
  "Return applications found in system and user desktop directories."
  (let ((dirs '("/usr/share/applications/"
                "/usr/local/share/applications/"
                "~/.local/share/applications/"
                "~/.nix-profile/share/applications/"
                "~/.guix-profile/share/applications/"
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

(defun universal-launcher--walk-sway-tree (node)
  "Return window candidates found below Sway tree NODE."
  (let* ((id (alist-get 'id node))
         (type (alist-get 'type node))
         (name (alist-get 'name node))
         (properties (alist-get 'window_properties node))
         (app-id (or (alist-get 'app_id node)
                     (alist-get 'class properties)))
         windows)
    (when (and id name app-id (equal type "con")
               (not (string-match-p "emacs" (downcase app-id))))
      (push (cons (format "%s (%s)" name app-id) id) windows))
    (dolist (child (append (alist-get 'nodes node)
                           (alist-get 'floating_nodes node)))
      (setq windows
            (nconc windows (universal-launcher--walk-sway-tree child))))
    windows))

(defun universal-launcher--windows ()
  "Return visible Sway windows."
  (with-temp-buffer
    (when (= 0 (call-process "swaymsg" nil t nil "-t" "get_tree" "-r"))
      (goto-char (point-min))
      (condition-case nil
          (universal-launcher--walk-sway-tree
           (json-parse-buffer :object-type 'alist
                              :array-type 'list
                              :null-object nil))
        (error nil)))))

(defun universal-launcher--focus-window (con-id)
  "Focus the Sway container identified by CON-ID."
  (call-process "swaymsg" nil nil nil (format "[con_id=%s] focus" con-id)))

(defun universal-launcher--buffers ()
  "Return ordinary Emacs buffers."
  (cl-loop for buffer in (buffer-list)
           for name = (buffer-name buffer)
           unless (string-prefix-p " " name)
           collect (cons name buffer)))

(defun universal-launcher--files ()
  "Return recent files that still exist."
  (cl-loop for file in recentf-list
           when (file-exists-p file)
           collect (cons (abbreviate-file-name file) file)))

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
  "Return common Google Chrome actions."
  '(("Focus Chrome" . focus)
    ("New Chrome tab" . new-tab)))

(defun universal-launcher--browser-action (action)
  "Perform Chrome ACTION."
  (pcase action
    ('focus
     (call-process "swaymsg" nil nil nil "[app_id=\\"google-chrome\\"] focus"))
    ('new-tab
     (universal-launcher--open-url "about:newtab"))))

(defun universal-launcher--search-engines ()
  "Return configured search engines as Consult candidates."
  universal-launcher--search-engines)

(defun universal-launcher--search-with-engine (engine-url)
  "Prompt for a query and search using ENGINE-URL."
  (universal-launcher--search (read-string "Search: ") engine-url))

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
     :action switch-to-buffer
     :disposition keep)
    (:name "Files" :narrow ?f :category file
     :items universal-launcher--files
     :action find-file
     :disposition keep)
    (:name "Bookmarks" :narrow ?k :category bookmark
     :items universal-launcher--bookmarks
     :action universal-launcher--open-url
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
(defun universal-launcher-popup (&optional _context-frame)
  "Select and execute an action from the universal Consult launcher."
  (interactive)
  (when-let* ((selected
               (consult--multi (universal-launcher--sources)
                               :prompt "Launch: "
                               :require-match nil
                               :sort nil
                               :history 'universal-launcher-history)))
    (or (plist-get (cdr selected) :disposition) 'close)))

(provide 'universal-launcher)
;;; universal-launcher.el ends here
