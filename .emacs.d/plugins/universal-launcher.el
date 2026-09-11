;;; universal-launcher.el --- one-line description  -*- lexical-binding: t; -*-
;;; universal-launcher.el --- Optimized universal launcher

;;; Commentary:
;; Simplified version that uses the existing Emacs frame

;;; Code:
(require 'recentf)
(recentf-mode 1)
(require 'cl-lib)
(require 'nerd-icons)
(require 'json)
(require 'seq)
(require 'subr-x)
(require 'thingatpt)
(require 'url-util)
(require 'calc)

;; Pre-grouped category structure for aesthetic grouping
(defvar universal-launcher--categories
  '((:name "Context" :icon "flash" :types (contextual custom-action))
    (:name "Active" :icon "device-desktop" :types (buffer running))
    (:name "Tasks" :icon "checklist" :types (agenda-task))
    (:name "Files & Apps" :icon "apps" :types (file app nix))
    (:name "Web" :icon "globe" :types (bookmark chrome-action))
    (:name "System" :icon "terminal" :types (command))
    (:name "Tools" :icon "wrench" :types (calculator kill-ring-item)))
  "Category definitions for the launcher.")

;; Enhanced cache system
(defvar universal-launcher--all-candidates nil "Pre-computed candidates.")
(defvar universal-launcher--last-update 0 "Last time candidates were updated.")
(defvar universal-launcher--update-interval 20 "Update interval in seconds.")
(defvar universal-launcher--previous-frame nil "The previous frame to return to.")

;; Icon cache with category-specific icons
(defvar universal-launcher--icon-cache
  (let ((cache (make-hash-table :test 'equal)))
    (puthash 'buffer     (nerd-icons-octicon "nf-oct-file_code"      :face '(:foreground "#3d424a"  :height 0.9)) cache)
    (puthash 'running    (nerd-icons-mdicon  "nf-md-monitor"          :face '(:foreground "#8b919a"  :height 0.9)) cache)
    (puthash 'app        (nerd-icons-faicon  "nf-fa-cube"             :face '(:foreground "#e0dcd4"  :height 0.9)) cache)
    (puthash 'nix        (nerd-icons-mdicon  "nf-md-nix"              :face '(:foreground "#7ebae4"  :height 0.9)) cache)
    (puthash 'chrome     (nerd-icons-faicon  "nf-fa-chrome"           :face '(:foreground "#e06c75"  :height 0.9)) cache)
    (puthash 'bookmark   (nerd-icons-octicon "nf-oct-bookmark"        :face '(:foreground "#b8c4b8"  :height 0.9)) cache)
    (puthash 'file       (nerd-icons-faicon  "nf-fa-file"             :face '(:foreground "#d4ccb4"  :height 0.9)) cache)
    (puthash 'command    (nerd-icons-octicon "nf-oct-terminal"        :face '(:foreground "#98c379"  :height 0.9)) cache)
    (puthash 'calculator (nerd-icons-faicon  "nf-fa-calculator"       :face '(:foreground "#56b6c2"  :height 0.9)) cache)
    (puthash "Active"    (nerd-icons-mdicon  "nf-md-view_dashboard"   :face '(:foreground "#61afef"  :weight bold :height 1.0)) cache)
    (puthash "Files & Apps" (nerd-icons-mdicon "nf-md-apps"           :face '(:foreground "#c678dd"  :weight bold :height 1.0)) cache)
    (puthash "Web"       (nerd-icons-mdicon  "nf-md-web"              :face '(:foreground "#e06c75"  :weight bold :height 1.0)) cache)
    (puthash "System"    (nerd-icons-mdicon  "nf-md-cog"              :face '(:foreground "#98c379"  :weight bold :height 1.0)) cache)
    (puthash "Tools"     (nerd-icons-mdicon  "nf-md-hammer_wrench"    :face '(:foreground "#d19a66"  :weight bold :height 1.0)) cache)
    (puthash "Context"   (nerd-icons-mdicon  "nf-md-lightning_bolt"   :face '(:foreground "#e5c07b"  :weight bold :height 1.0)) cache)
    (puthash "Tasks"     (nerd-icons-octicon "nf-oct-checklist"       :face '(:foreground "#61afef"  :weight bold :height 1.0)) cache)
    cache)
  "Pre-loaded icon cache with consistent styling.")

;; Add fallback icon function
(defun universal-launcher--get-icon-safe (type)
  "Get icon for TYPE with fallback."
  (condition-case nil
      (or (gethash type universal-launcher--icon-cache)
          (nerd-icons-octicon "nf-oct-dash" :face '(:foreground "#abb2bf" :height 0.9)))
    (error "")))

(defun universal-launcher--get-file-icon (filename)
  "Get appropriate icon for FILENAME."
  (nerd-icons-icon-for-file filename))

(defun universal-launcher--grouped-candidates ()
  "Return candidates grouped by category."
  (let ((candidates '())
        (category-handlers (make-hash-table :test 'eq)))

    ;; Define ALL handlers FIRST - before processing categories
    (puthash 'buffer
             (lambda ()
               (mapcar (lambda (buffer)
                         (cons (format "%s Buffer: %s"
                                       (universal-launcher--get-icon 'buffer)
                                       (buffer-name buffer))
                               (list 'buffer buffer)))
                       (buffer-list)))
             category-handlers)

    (puthash 'running
             (lambda ()
               (mapcar (lambda (app)
                         (cons (format "%s Running: %s"
                                       (universal-launcher--get-icon 'running)
                                       (car app))
                               (list 'running (cdr app))))
                       (universal-launcher--get-running-applications)))
             category-handlers)

    (puthash 'file
             (lambda ()
               (mapcar (lambda (file)
                         (let ((filename (file-name-nondirectory file))
                               (directory (file-name-directory file)))
                           (cons (format "%s File: %s  %s"
                                         (universal-launcher--get-file-icon file)
                                         filename
                                         (propertize (abbreviate-file-name directory) 'face 'font-lock-comment-face))
                                 (list 'file file))))
                       recentf-list))
             category-handlers)

    (puthash 'app
             (lambda ()
               (mapcar (lambda (app)
                         (cons (format "%s %s"
                                       (universal-launcher--get-icon 'app)
                                       (car app))
                               (list 'app (cdr app))))
                       (universal-launcher--get-applications)))
             category-handlers)

    (puthash 'nix
             (lambda ()
               (mapcar (lambda (app)
                         (cons (format "%s Nix: %s"
                                       (universal-launcher--get-icon 'nix)
                                       (car app))
                               (list 'app (cdr app))))
                       (universal-launcher--get-nix-applications)))
             category-handlers)

    (puthash 'bookmark
             (lambda ()
               (mapcar (lambda (bookmark)
                         (cons (format "%s Bookmark: %s"
                                       (universal-launcher--get-icon 'bookmark)
                                       (car bookmark))
                               (list 'bookmark (cdr bookmark))))
                       (universal-launcher--parse-org-bookmarks
                        (expand-file-name "~/org/bookmarks.org"))))
             category-handlers)

    (puthash 'chrome-action
             (lambda ()
               (mapcar (lambda (action)
                         (cons (format "%s Chrome: %s"
                                       (universal-launcher--get-icon 'chrome)
                                       (car action))
                               (list 'chrome-action (cdr action))))
                       (universal-launcher--get-chrome-actions)))
             category-handlers)

    (puthash 'command
             (lambda ()
               (mapcar (lambda (cmd)
                         (cons (format "%s Command %s"
                                       (universal-launcher--get-icon 'command)
                                       cmd)
                               (list 'command cmd)))
                       (universal-launcher--get-system-commands)))
             category-handlers)

    (puthash 'calculator
             (lambda ()
               (list (cons (format "%s Calculator: Enter math expression"
                                   (universal-launcher--get-icon 'calculator))
                           (list 'calculator 'ready))))
             category-handlers)

    ;; NEW HANDLERS - Add these BEFORE processing categories
    (puthash 'contextual
             #'universal-launcher--get-contextual-actions
             category-handlers)

    (puthash 'agenda-task
             #'universal-launcher--get-agenda-tasks
             category-handlers)

    (puthash 'kill-ring-item
             #'universal-launcher--get-kill-ring
             category-handlers)

    (puthash 'custom-action
             #'universal-launcher--get-custom-actions
             category-handlers)

    ;; NOW process categories - handlers are all defined above
    (dolist (category universal-launcher--categories)
      (let* ((cat-name (plist-get category :name))
             (cat-icon (gethash cat-name universal-launcher--icon-cache))
             (types (plist-get category :types))
             (section-items '()))

        (dolist (type types)
          (when-let* ((handler (gethash type category-handlers)))
            (setq section-items (append section-items (funcall handler)))))

        (when section-items
          (push (cons (format "%s  %s " cat-icon cat-name) 'separator) candidates)
          (dolist (item section-items)
            (push (cons (concat "   " (car item)) (cdr item)) candidates)))))

    (nreverse candidates)))

(defun universal-launcher--update-candidates (&optional force)
  "Update cached candidates if needed or FORCE is non-nil."
  (when (or force
            (> (- (float-time) universal-launcher--last-update)
               universal-launcher--update-interval))
    (setq universal-launcher--all-candidates (universal-launcher--grouped-candidates))
    (setq universal-launcher--last-update (float-time))))

(defun universal-launcher--get-icon (type)
  "Get cached icon for TYPE instantly."
  (gethash type universal-launcher--icon-cache ""))

(defun universal-launcher--get-running-applications ()
  "Get list of currently running applications."
  (let (apps)
    (with-temp-buffer
      (when (= 0 (call-process "swaymsg" nil t nil "-t" "get_tree" "-r"))
        (goto-char (point-min))
        (condition-case nil
            (let ((tree (json-parse-buffer :object-type 'alist
                                           :array-type 'list
                                           :null-object nil)))
              (cl-labels
                  ((walk (node)
                     (let* ((id (alist-get 'id node))
                            (type (alist-get 'type node))
                            (name (alist-get 'name node))
                            (app-id (or (alist-get 'app_id node)
                                        (alist-get 'class
                                                   (alist-get 'window_properties node)))))
                       (when (and id name app-id
                                  (equal type "con")
                                  (not (string-match-p "emacs" (downcase app-id))))
                         (push (cons (format "%s (%s)" name app-id)
                                     (list id name))
                               apps))
                       (mapc #'walk (alist-get 'nodes node))
                       (mapc #'walk (alist-get 'floating_nodes node)))))
                (walk tree)))
          (error nil))))
    apps))

(defun universal-launcher--get-applications ()
  "Get list of system applications from .desktop files.
Nix profile applications have a dedicated handler."
  (let ((apps '())
        (dirs '("/usr/share/applications/"
                "/usr/local/share/applications/"
                "~/.local/share/applications/"
                "~/.guix-profile/share/applications/"
                "/run/current-system/profile/share/applications/")))
    (dolist (dir dirs)
      (when (file-directory-p (expand-file-name dir))
        (dolist (file (directory-files (expand-file-name dir) t "\\.desktop$"))
          (with-temp-buffer
            (insert-file-contents file)
            (when (re-search-forward "^Name=\\(.+\\)$" nil t)
              (let ((name (match-string 1))
                    exec-line)
                (goto-char (point-min))
                (when (re-search-forward "^Exec=\\(.+\\)$" nil t)
                  (setq exec-line (match-string 1))
                  (push (cons name (replace-regexp-in-string "%[FfUu]" "" exec-line))
                        apps))))))))
    (cl-remove-duplicates apps :test (lambda (a b) (string= (car a) (car b))) :from-end t)))

(defun universal-launcher--get-nix-applications ()
  "Get Nix (nixpkgs) applications from the user profile's desktop entries."
  (let* ((appsdir (expand-file-name "~/.nix-profile/share/applications"))
         (apps '()))
    (when (file-directory-p appsdir)
      (dolist (file (directory-files appsdir t "\\.desktop\\'"))
        (with-temp-buffer
          (insert-file-contents file)
          (goto-char (point-min))
          (let (name exec type no-display hidden
                     (end (save-excursion
                            (if (re-search-forward "^\\[Desktop Action" nil t)
                                (match-beginning 0)
                              (point-max)))))
            (when (re-search-forward "^\\[Desktop Entry\\]" nil t)
              (while (re-search-forward
                      "^\\([A-Za-z0-9-]+\\)[[:space:]]*=[[:space:]]*\\(.*\\)$" end t)
                (pcase (match-string 1)
                  ("Name"      (unless name (setq name (match-string 2))))
                  ("Exec"      (unless exec (setq exec (match-string 2))))
                  ("Type"      (setq type (match-string 2)))
                  ("NoDisplay" (setq no-display (string= (match-string 2) "true")))
                  ("Hidden"    (setq hidden (string= (match-string 2) "true"))))))
            (when (and name exec (equal type "Application")
                       (not no-display) (not hidden))
              (push (cons name
                          (string-trim
                           (replace-regexp-in-string "%[a-zA-Z]" "" exec)))
                    apps))))))
    (cl-remove-duplicates apps :test (lambda (a b) (string= (car a) (car b))) :from-end t)))

;; TODO Calculator Module
;; Calculator Module
(defun universal-launcher--is-calculator-input (input)
  "Check if INPUT is a math expression."
  (and (not (string-empty-p input))
       (not (string-match-p "^[[:space:]]*$" input))
       ;; Allow more mathematical symbols and functions
       (string-match-p "^[0-9+\\-*/().,^ %!sincotaqrexplog]+$" input)
       ;; Must contain at least one operator or math function
       (or (string-match-p "[+\\-*/^%]" input)
           (string-match-p "\\(sin\\|cos\\|tan\\|sqrt\\|exp\\|log\\)" input))
       ;; Must contain at least one number
       (string-match-p "[0-9]" input)))

(defun universal-launcher--calculate (expr)
  "Calculate mathematical expression EXPR using calc."
  (condition-case err
      (let* ((clean-expr (string-trim expr))
             ;; Replace common notations
             (calc-expr (replace-regexp-in-string "\\^" "**" clean-expr))
             (calc-expr (replace-regexp-in-string "×" "*" calc-expr))
             (calc-expr (replace-regexp-in-string "÷" "/" calc-expr))
             (result (calc-eval calc-expr)))
        (if (and result
                 (stringp result)
                 (not (string= result ""))
                 (not (string-match-p "\\(Error\\|Bad\\)" result))
                 ;; Accept various number formats including scientific notation
                 (or (string-match-p "^[-+]?[0-9]+\\.?[0-9]*\\(?:[eE][-+]?[0-9]+\\)?$" result)
                     (string-match-p "^[-+]?[0-9]+/[0-9]+$" result))) ; fractions
            result
          nil))
    (error nil)))

(defun universal-launcher--copy-to-clipboard (text)
  "Copy TEXT to the Wayland clipboard."
  (cond
   ((display-graphic-p)
    (gui-set-selection 'CLIPBOARD text))
   ((executable-find "wl-copy")
    (let ((process (start-process "wl-copy" nil "wl-copy")))
      (process-send-string process text)
      (process-send-eof process)))
   (t
    (kill-new text)
    (message "Copied to Emacs kill ring (install wl-copy for the system clipboard)"))))

;; Enhanced calculator handler for the main popup function
(defun universal-launcher--handle-calculator-input (input)
  "Handle calculator INPUT with immediate calculation."
  (let ((result (universal-launcher--calculate input)))
    (if result
        (progn
          (universal-launcher--copy-to-clipboard result)
          (message "%s = %s (copied to clipboard)" input result)
          ;; If in a buffer, optionally insert the result
          (when (and universal-launcher--previous-frame
                     (frame-live-p universal-launcher--previous-frame))
            (with-selected-frame universal-launcher--previous-frame
              (when (and (not (minibufferp))
                         (not buffer-read-only)
                         (y-or-n-p "Insert result at point? "))
                (insert result)))))
      (message "Invalid expression: %s" input))))

(defun universal-launcher--get-system-commands ()
  "Get system commands from PATH."
  (let ((commands '()))
    (dolist (dir (parse-colon-path (getenv "PATH")))
      (when (file-directory-p dir)
        (dolist (file (directory-files dir t))
          (when (and (file-executable-p file)
                     (not (file-directory-p file))
                     (not (backup-file-name-p file)))
            (push (file-name-nondirectory file) commands)))))
    (cl-remove-duplicates commands :test #'string=)))

(defun universal-launcher--chrome-program ()
  "Return the installed Google Chrome executable."
  (or (executable-find "google-chrome-stable")
      (executable-find "google-chrome")))

(defun universal-launcher--get-chrome-actions ()
  "Get common Google Chrome actions."
  (when (universal-launcher--chrome-program)
    (append
     (when (= 0 (call-process "pgrep" nil nil nil "-f" "google-chrome"))
       '(("Focus window" focus-window)))
     '(("Open new tab" new-tab)
       ("Open Google" open-url "https://www.google.com")
       ("Open GitHub" open-url "https://github.com")
       ("Open YouTube" open-url "https://www.youtube.com")
       ("Open Wikipedia" open-url "https://en.wikipedia.org")))))

(defun universal-launcher--parse-org-bookmarks (file)
  "Parse bookmarks from an org FILE with support for various formats."
  (let ((bookmarks '()))
    (when (file-exists-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (org-mode)
        ;; Use org-element-map to parse the entire buffer
        (org-element-map (org-element-parse-buffer) 'link
          (lambda (link)
            (when (member (org-element-property :type link) '("http" "https"))
              (let* ((raw-link (org-element-property :raw-link link))
                     ;; Extract just the URL part using regex, excluding initial [ or ]
                     (url-candidate (if (string-match "^\\(https?://[^]\\[]+\\)" raw-link)
                                        (match-string 1 raw-link)
                                      raw-link))
                     ;; Remove trailing slash if present and it's not the only char after "://"
                     (url (if (and url-candidate
                                   (> (length url-candidate) (if (string-prefix-p "https" url-candidate) 8 7)) ; "https://" is 8, "http://" is 7
                                   (string-suffix-p "/" url-candidate))
                              (substring url-candidate 0 -1)
                            url-candidate))
                     (desc (or (org-element-interpret-data
                                (org-element-contents link))
                               (universal-launcher--extract-domain url))))
                (when url ; Ensure URL is not nil
                  (push (cons (if (string-empty-p desc)
                                  (universal-launcher--extract-domain url)
                                desc)
                              url)
                        bookmarks))))))
        ;; Also parse plain URLs
        (goto-char (point-min))
        ;; Regex now excludes ']', '[', space, tab, and newline from the URL part
        (while (re-search-forward "\\bhttps?://[^]\\[ \t\n]+" nil t)
          (let* ((url-candidate (match-string-no-properties 0))
                 ;; Remove trailing slash if present
                 (url (if (and url-candidate
                               (> (length url-candidate) (if (string-prefix-p "https" url-candidate) 8 7))
                               (string-suffix-p "/" url-candidate))
                          (substring url-candidate 0 -1)
                        url-candidate)))
            (when url ; Ensure URL is not nil
              (unless (rassoc url bookmarks) ; Check against the processed URL
                (push (cons (universal-launcher--extract-domain url) url)
                      bookmarks)))))))
    ;; Sort by description and remove duplicates by URL
    (cl-remove-duplicates
     (sort bookmarks (lambda (a b) (string< (car a) (car b))))
     :test (lambda (a b) (string= (cdr a) (cdr b)))
     :from-end t)))

(defun universal-launcher--extract-domain (url)
  "Extract readable domain name from URL."
  (if (string-match "https?://\\([^/]+\\)" url)
      (let ((domain (match-string 1 url)))
        (if (string-match "^www\\." domain)
            (substring domain 4)
          domain))
    url))

(defun universal-launcher--focus-running-application (app-info)
  "Focus running application using APP-INFO."
  (call-process "swaymsg" nil nil nil
                (format "[con_id=%s] focus" (car app-info))))

(defun universal-launcher--run-application (exec-string)
  "Run application with EXEC-STRING."
  (let* ((exec-parts (split-string-and-unquote exec-string))
         (command (car exec-parts)))
    (apply #'start-process command nil command (cdr exec-parts))))

(defun universal-launcher--open-url (url)
  "Open URL in Google Chrome."
  (when-let* ((chrome (universal-launcher--chrome-program)))
    (start-process "google-chrome" nil chrome "--new-tab" url)))

(defun universal-launcher--handle-chrome-action (action)
  "Handle Google Chrome ACTION."
  (pcase (car action)
    ('focus-window
     (call-process "swaymsg" nil nil nil "[app_id=\"google-chrome\"] focus"))
    ('new-tab
     (universal-launcher--open-url "about:newtab"))
    ('open-url
     (universal-launcher--open-url (cadr action)))))

(defun universal-launcher--handle-bookmark (url)
  "Open URL in Google Chrome."
  (universal-launcher--open-url url))

(defun universal-launcher--run-command (command)
  "Run COMMAND."
  (start-process command nil command))

;; Web search function
(defcustom universal-launcher-default-search-engine "Google"
  "Default search engine for web searches."
  :type 'string
  :group 'universal-launcher)

(defvar universal-launcher--last-search-engine nil
  "Last used search engine.")

(defun universal-launcher--web-search (query)
  "Search the web with QUERY using default browser.
If QUERY looks like a URL, navigate directly to it.
Otherwise, prompt for a search engine.
C-u prefix forces engine re-selection."
  (interactive
   (list (cond
          ((use-region-p)
           (buffer-substring-no-properties (region-beginning) (region-end)))
          ((thing-at-point 'symbol t))
          (t nil))))

  (let* ((search-engines
          '(("Google" . "https://www.google.com/search?q=")
            ("Reddit" . "https://www.reddit.com/search/?q=")
            ("Nix Packages" . "https://search.nixos.org/packages?channel=25.05&query=")
            ("NixOS Options" . "https://search.nixos.org/options?channel=25.05&query=")
            ("GitHub" . "https://github.com/search?q=")
            ("Google Maps" . "https://www.google.com/maps/search/")
            ("Rust Docs" . "https://doc.rust-lang.org/std/?search=")
            ("MELPA" . "https://melpa.org/#/?q=")
            ("Emacs Docs" . "https://www.gnu.org/software/emacs/manual/html_node/emacs/index.html?search=")
            ))
         (engine (completing-read
                  (format "Search engine (default %s): "
                          (or universal-launcher--last-search-engine
                              universal-launcher-default-search-engine))
                  (mapcar #'car search-engines)
                  nil t nil nil
                  (or universal-launcher--last-search-engine
                      universal-launcher-default-search-engine)))
         (url-base (cdr (assoc engine search-engines)))
         (query (or query
                    (read-string (format "Search %s: " engine)
                                 (thing-at-point 'symbol t)))))
    (setq universal-launcher--last-search-engine engine)
    (if (string-match-p "^\\(https?://\\|www\\.\\)" query)
        (universal-launcher--open-url
         (if (string-prefix-p "www." query)
             (concat "https://" query)
           query))
      (universal-launcher--open-url
       (concat url-base (url-hexify-string query))))))

;; ============================================================================
;; FRECENCY SYSTEM - The Foundation of Intelligence
;; ============================================================================

(defvar universal-launcher--history-file
  (expand-file-name "universal-launcher-history" user-emacs-directory)
  "File to persist launch history.")

(defvar universal-launcher--launch-history nil
  "Alist of (item . (count . last-time)).")

(defun universal-launcher--load-history ()
  "Load launch history from disk."
  (when (file-exists-p universal-launcher--history-file)
    (condition-case nil
        (with-temp-buffer
          (insert-file-contents universal-launcher--history-file)
          (setq universal-launcher--launch-history (read (current-buffer))))
      (error
       (setq universal-launcher--launch-history nil)
       (message "Warning: Could not load launcher history")))))

(defun universal-launcher--save-history ()
  "Save launch history to disk."
  (condition-case nil
      (with-temp-buffer
        (prin1 universal-launcher--launch-history (current-buffer))
        (write-region (point-min) (point-max) universal-launcher--history-file nil 'silent))
    (error (message "Warning: Could not save launcher history"))))

(defun universal-launcher--record-launch (selection)
  "Record SELECTION in history with frecency scoring."
  (let* ((entry (assoc selection universal-launcher--launch-history))
         (count (if entry (car (cdr entry)) 0))
         (now (float-time)))
    (setf (alist-get selection universal-launcher--launch-history nil nil #'equal)
          (cons (1+ count) now))
    (run-with-idle-timer 1 nil #'universal-launcher--save-history)))

(defun universal-launcher--frecency-score (item-text)
  "Calculate frecency score for ITEM-TEXT.
Combines frequency (usage count) with recency (time decay)."
  (if-let* ((data (alist-get item-text universal-launcher--launch-history nil nil #'equal)))
      (let* ((count (car data))
             (last-time (cdr data))
             (age-days (/ (- (float-time) last-time) 86400.0))
             ;; Exponential decay: half-life of 7 days
             (recency-factor (exp (/ (- age-days) 7.0))))
        (* count recency-factor))
    0))

;; ============================================================================
;; CONTEXTUAL ACTIONS - Mode-Aware Intelligence
;; ============================================================================

(defun universal-launcher--get-contextual-actions ()
  "Get actions relevant to current buffer's major mode and project."
  (when (and universal-launcher--previous-frame
             (frame-live-p universal-launcher--previous-frame))
    (with-selected-frame universal-launcher--previous-frame
      (let ((actions '())
            (icon (nerd-icons-mdicon "nf-md-lightning_bolt" :face '(:foreground "#e5c07b" :height 0.9))))

        ;; Universal org-capture (always available)
        (when (fboundp 'org-capture)
          (push (cons (format "%s Capture: Quick note" icon)
                      (list 'function #'org-capture))
                actions))

        ;; Mode-specific actions
        (pcase major-mode
          ;; Org Mode
          ('org-mode
           (when (fboundp 'org-agenda)
             (push (cons (format "%s Org: Open Agenda" icon)
                         (list 'function #'org-agenda))
                   actions))
           (push (cons (format "%s Org: Refile" icon)
                       (list 'function #'org-refile))
                 actions)
           (push (cons (format "%s Org: Archive subtree" icon)
                       (list 'function #'org-archive-subtree))
                 actions)
           (when (fboundp 'org-set-tags-command)
             (push (cons (format "%s Org: Set tags" icon)
                         (list 'function #'org-set-tags-command))
                   actions)))

          ;; Go Mode
          ('go-mode
           (let ((default-directory (or (locate-dominating-file default-directory "go.mod")
                                        default-directory)))
             (push (cons (format "%s Go: Run tests" icon)
                         (list 'async-shell "go test -v ./..."))
                   actions)
             (push (cons (format "%s Go: Build" icon)
                         (list 'async-shell "go build"))
                   actions)
             (push (cons (format "%s Go: Run main" icon)
                         (list 'async-shell "go run ."))
                   actions)
             (push (cons (format "%s Go: Tidy modules" icon)
                         (list 'async-shell "go mod tidy"))
                   actions)
             (push (cons (format "%s Go: Format code" icon)
                         (list 'function #'gofmt))
                   actions)))

          ;; Rust Mode
          ('rust-mode
           (let ((default-directory (or (locate-dominating-file default-directory "Cargo.toml")
                                        default-directory)))
             (push (cons (format "%s Rust: Build" icon)
                         (list 'async-shell "cargo build"))
                   actions)
             (push (cons (format "%s Rust: Run tests" icon)
                         (list 'async-shell "cargo test"))
                   actions)
             (push (cons (format "%s Rust: Run" icon)
                         (list 'async-shell "cargo run"))
                   actions)
             (push (cons (format "%s Rust: Check" icon)
                         (list 'async-shell "cargo check"))
                   actions)))

          ;; Emacs Lisp Mode
          ('emacs-lisp-mode
           (push (cons (format "%s Elisp: Eval buffer" icon)
                       (list 'function #'eval-buffer))
                 actions)
           (push (cons (format "%s Elisp: Eval defun" icon)
                       (list 'function #'eval-defun))
                 actions)
           (push (cons (format "%s Elisp: Load file" icon)
                       (list 'function #'load-file))
                 actions))

          ;; Nix Mode
          ('nix-mode
           (push (cons (format "%s Nix: Rebuild switch" icon)
                       (list 'async-shell "sudo nixos-rebuild switch"))
                 actions)
           (push (cons (format "%s Nix: Rebuild test" icon)
                       (list 'async-shell "sudo nixos-rebuild test"))
                 actions)
           (push (cons (format "%s Nix: Update flake" icon)
                       (list 'async-shell "nix flake update"))
                 actions))

          ;; Markdown Mode
          ('markdown-mode
           (when (fboundp 'markdown-preview)
             (push (cons (format "%s Markdown: Preview" icon)
                         (list 'function #'markdown-preview))
                   actions))
           (push (cons (format "%s Markdown: Export to HTML" icon)
                       (list 'function #'markdown-export))
                 actions)))

        (nreverse actions)))))

;; ============================================================================
;; ORG AGENDA INTEGRATION
;; ============================================================================

(defun universal-launcher--get-agenda-tasks ()
  "Get today's agenda tasks."
  (when (and (fboundp 'org-map-entries)
             (bound-and-true-p org-agenda-files))
    (let ((tasks '())
          (icon (nerd-icons-octicon "nf-oct-checklist" :face '(:foreground "#61afef" :height 0.9))))
      (org-map-entries
       (lambda ()
         (let* ((heading (org-get-heading t t t t))
                (todo-state (org-get-todo-state))
                (priority (org-get-priority (thing-at-point 'line t)))
                (tags (org-get-tags))
                (display (format "%s %s %s%s"
                                 icon
                                 (propertize (or todo-state "TODO")
                                             'face 'org-todo)
                                 heading
                                 (if tags
                                     (propertize (format " :%s:" (string-join tags ":"))
                                                 'face 'org-tag)
                                   ""))))
           (push (cons display
                       (list 'org-task (point-marker)))
                 tasks)))
       "+TODO=\"TODO\"|+TODO=\"NEXT\"|+TODO=\"STARTED\""
       'agenda)
      (nreverse tasks))))

(defun universal-launcher--jump-to-task (marker)
  "Jump to org task at MARKER."
  (when (marker-buffer marker)
    (switch-to-buffer (marker-buffer marker))
    (goto-char marker)
    (org-show-context)
    (org-reveal)
    (recenter)))

;; ============================================================================
;; KILL RING SEARCH
;; ============================================================================

(defun universal-launcher--get-kill-ring ()
  "Get recent kill ring entries."
  (let ((icon (nerd-icons-faicon "nf-fa-clipboard" :face '(:foreground "#c678dd" :height 0.9))))
    (cl-loop for item in (seq-take kill-ring 15)
             for idx from 1
             when (and (stringp item)
                       (> (length item) 0)
                       (not (string-match-p "^[[:space:]]*$" item)))
             collect (cons (format "%s Clip #%d: %s"
                                   icon
                                   idx
                                   (truncate-string-to-width
                                    (replace-regexp-in-string "\n" "<- " item)
                                    60 nil nil "..."))
                           (list 'kill-ring item)))))

(defun universal-launcher--yank-from-ring (text)
  "Insert TEXT from kill ring at point."
  (when (and universal-launcher--previous-frame
             (frame-live-p universal-launcher--previous-frame))
    (with-selected-frame universal-launcher--previous-frame
      (when (not buffer-read-only)
        (insert text)
        (message "Inserted from kill ring")))))

;; ============================================================================
;; CUSTOM ACTIONS/SCRIPTS
;; ============================================================================

(defcustom universal-launcher-custom-actions nil
  "Custom actions as ((name . (type . action))).
Type can be 'function, 'shell-command, or 'async-shell.

Examples:
  ((\"Daily Review\" . (function . my-daily-review-fn))
   (\"Rebuild NixOS\" . (async-shell . \"sudo nixos-rebuild switch\"))
   (\"Git Status\" . (shell-command . \"git status\")))"
  :type '(alist :key-type string
                :value-type (cons symbol sexp))
  :group 'universal-launcher)

(defun universal-launcher--get-custom-actions ()
  "Get user-defined custom actions."
  (let ((icon (nerd-icons-mdicon "nf-md-star" :face '(:foreground "#e5c07b" :height 0.9))))
    (mapcar (lambda (action)
              (cons (format "%s Custom: %s" icon (car action))
                    (list 'custom-action (cdr action))))
            universal-launcher-custom-actions)))

(defun universal-launcher--execute-custom-action (action)
  "Execute custom ACTION."
  (let ((type (car action))
        (cmd (cdr action)))
    (pcase type
      ('function
       (if (functionp cmd)
           (funcall cmd)
         (message "Error: Not a valid function: %s" cmd)))
      ('shell-command
       (shell-command cmd))
      ('async-shell
       (async-shell-command cmd))
      (_
       (message "Unknown action type: %s" type)))))

(defun universal-launcher-popup (&optional context-frame)
  "World-class launcher for Emacs."
  (interactive)

  ;; A transient launcher frame can still use the previously active Emacs
  ;; frame as context for buffer-aware actions.
  (setq universal-launcher--previous-frame
        (or context-frame (selected-frame)))

  ;; Force update if needed
  (universal-launcher--update-candidates)

  ;; Create candidates list with nil as completion table to allow any input
  (let* ((candidates (mapcar #'car universal-launcher--all-candidates))
         (prompt "Launch (or enter math expression): ")
         (selection
          (minibuffer-with-setup-hook
              (lambda ()
                ;; Allow any input, not just candidates
                (setq-local completion-styles '(orderless basic))
                (setq-local completion-ignore-case t)
                (setq-local completion-category-overrides nil))
            (completing-read prompt
                             ;; Use a function that always returns all candidates
                             ;; This allows typing anything while still showing candidates
                             (lambda (string pred action)
                               (if (eq action 'metadata)
                                   '(metadata (category . universal-launcher))
                                 (all-completions string candidates pred)))
                             nil    ; predicate
                             nil    ; require-match = nil allows any input!
                             nil    ; initial-input
                             nil    ; hist
                             nil))) ; def
         (candidate (cdr (assoc selection universal-launcher--all-candidates)))
         (disposition 'close))

    (cond
     ;; Empty input - do nothing
     ((string-empty-p selection) nil)

     ;; Calculator check - prioritize this before other matches
     ((universal-launcher--is-calculator-input selection)
      (universal-launcher--handle-calculator-input selection))

     ;; Separator - do nothing
     ((eq candidate 'separator) nil)

     ;; Handle matched candidates
     (candidate
      (let ((type (car candidate))
            (item (cadr candidate)))
        (pcase type
          ('buffer (switch-to-buffer item))
          ('running (universal-launcher--focus-running-application item))
          ('app (universal-launcher--run-application item))
          ('chrome-action (universal-launcher--handle-chrome-action item))
          ('bookmark (universal-launcher--handle-bookmark item))
          ('file (find-file item))
          ('command (universal-launcher--run-command item))
          ('calculator (message "Type a math expression like: 2+2, sqrt(16), sin(45)"))
          ('org-task (universal-launcher--jump-to-task item))
          ('kill-ring (universal-launcher--yank-from-ring item))
          ('custom-action (universal-launcher--execute-custom-action item))
          ('function (funcall item))
          ('async-shell
           (let ((default-directory (or (locate-dominating-file default-directory ".git")
                                        default-directory)))
             (async-shell-command item)))
          ('shell-command
           (let ((default-directory (or (locate-dominating-file default-directory ".git")
                                        default-directory)))
             (shell-command item)))
          (_ (message "Unknown action type: %s" type)))
        (setq disposition
              (cond
               ((eq type 'kill-ring) 'context)
               ((memq type '(buffer file org-task custom-action function
                                     async-shell shell-command))
                'keep)
               (t 'close)))))

     ;; Web search fallback - only if not a calculator expression
     ((and (not candidate)
           (not (string-empty-p selection))
           (not (universal-launcher--is-calculator-input selection)))
      (universal-launcher--web-search selection)))

    disposition))

;; Set up background update timer
(run-with-timer universal-launcher--update-interval
                universal-launcher--update-interval
                #'universal-launcher--update-candidates)

(provide 'universal-launcher)
;;; universal-launcher.el ends here
