;;; agent-shell-cockpit-test.el --- Tests for agent-shell-cockpit -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)

;; Keep these unit tests independent of agent-shell's dependency graph.
(provide 'agent-shell)
(load (expand-file-name "../plugins/agent-shell-cockpit.el"
                        (file-name-directory load-file-name))
      nil t)

(defmacro agent-shell-cockpit-test--with-buffers (names &rest body)
  "Create temporary buffers named NAMES while evaluating BODY."
  (declare (indent 1) (debug (form body)))
  `(let ((buffers (mapcar #'generate-new-buffer ,names)))
     (unwind-protect
         (progn ,@body)
       (dolist (buffer buffers)
         (when (buffer-live-p buffer)
           (kill-buffer buffer))))))

(ert-deftest agent-shell-cockpit-maps-agent-shell-statuses ()
  (agent-shell-cockpit-test--with-buffers '(" working")
    (let ((buffer (car buffers)))
      (dolist (case '((blocked . attention) (busy . working) (ready . ready)))
        (cl-letf (((symbol-function 'agent-shell-status)
                   (lambda (&rest _) (car case))))
          (should (eq (agent-shell-cockpit--status buffer) (cdr case))))))))

(ert-deftest agent-shell-cockpit-sorts-attention-first ()
  (agent-shell-cockpit-test--with-buffers '(" ready" " blocked" " busy")
    (let ((statuses `((,(nth 0 buffers) . ready)
                      (,(nth 1 buffers) . blocked)
                      (,(nth 2 buffers) . busy))))
      (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () buffers))
                ((symbol-function 'agent-shell-status)
                 (lambda (&key shell-buffer)
                   (alist-get shell-buffer statuses))))
        (should (equal (agent-shell-cockpit--sorted-buffers)
                       (list (nth 1 buffers) (nth 2 buffers) (nth 0 buffers))))))))

(ert-deftest agent-shell-cockpit-render-has-one-row-per-session ()
  (agent-shell-cockpit-test--with-buffers '(" ready" " blocked")
    (dolist (buffer buffers)
      (with-current-buffer buffer
        (setq default-directory "/tmp/")))
    (with-temp-buffer
      (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () buffers))
                ((symbol-function 'agent-shell-status)
                 (lambda (&key shell-buffer)
                   (if (eq shell-buffer (nth 1 buffers)) 'blocked 'ready)))
                ((symbol-function 'window-body-width) (lambda (&rest _) 100)))
        (agent-shell-cockpit--render)
        (dolist (session buffers)
          (goto-char (point-min))
          (let ((count 0))
            (while (< (point) (point-max))
              (when (eq (get-text-property (point) 'agent-shell-cockpit-buffer)
                        session)
                (setq count (1+ count))
                (goto-char (or (next-single-property-change
                                (point) 'agent-shell-cockpit-buffer nil (point-max))
                               (point-max))))
              (unless (eobp) (forward-char 1)))
            (should (= count 1))))))))

(ert-deftest agent-shell-cockpit-render-merges-attention-into-sessions ()
  (agent-shell-cockpit-test--with-buffers '(" ready" " blocked")
    (dolist (buffer buffers)
      (with-current-buffer buffer
        (setq default-directory "/tmp/")))
    (with-temp-buffer
      (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () buffers))
                ((symbol-function 'agent-shell-status)
                 (lambda (&key shell-buffer)
                   (if (eq shell-buffer (nth 1 buffers)) 'blocked 'ready)))
                ((symbol-function 'window-body-width) (lambda (&rest _) 100)))
        (agent-shell-cockpit--render)
        (should (= (how-many "Sessions" (point-min) (point-max)) 1))
        (should-not (let ((case-fold-search nil))
                      (save-excursion
                        (goto-char (point-min))
                        (search-forward "Needs attention" nil t))))
        (should (save-excursion
                  (goto-char (point-min))
                  (search-forward "[NEEDS ATTENTION]" nil t)))
        (should (save-excursion
                  (goto-char (point-min))
                  (search-forward
                   (string-trim (car agent-shell-cockpit--ascii-art))
                   nil t)))))))

(ert-deftest agent-shell-cockpit-ascii-art-has-native-emacs-styling ()
  (let* ((spec (get 'agent-shell-cockpit-title 'face-defface-spec))
         (attributes (cdr (assq t spec))))
    (should (memq 'error (plist-get attributes :inherit)))
    (should (= (plist-get attributes :height) 1.7))))

(ert-deftest agent-shell-cockpit-ascii-art-is-left-aligned ()
  (with-temp-buffer
    (agent-shell-cockpit--insert-ascii-art)
    (goto-char (point-min))
    (dolist (line agent-shell-cockpit--ascii-art)
      (should (looking-at (regexp-quote (concat "  " line))))
      (forward-line 1))))

(ert-deftest agent-shell-cockpit-render-includes-agent-session-title ()
  (agent-shell-cockpit-test--with-buffers '(" Codex Agent @ cockpit")
    (let ((session (car buffers)))
      (with-current-buffer session
        (setq default-directory "/tmp/cockpit/"
              agent-shell--state
              '((:session . ((:title . "Improve the cockpit display"))))))
      (with-temp-buffer
        (cl-letf (((symbol-function 'agent-shell-buffers)
                   (lambda () buffers))
                  ((symbol-function 'agent-shell-status)
                   (lambda (&rest _) 'ready))
                  ((symbol-function 'window-body-width)
                   (lambda (&rest _) 100)))
          (agent-shell-cockpit--render)
          (should (save-excursion
                    (goto-char (point-min))
                    (search-forward "Improve the cockpit display" nil t)))
          (should (save-excursion
                    (goto-char (point-min))
                    (search-forward "Codex Agent @ cockpit  ·  /tmp/cockpit/"
                                    nil t))))))))

(ert-deftest agent-shell-cockpit-refresh-preserves-selected-session ()
  (agent-shell-cockpit-test--with-buffers '(" alpha" " beta")
    (with-temp-buffer
      (let ((agent-shell-cockpit--buffer (current-buffer))
            (inhibit-read-only t))
        (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () buffers))
                  ((symbol-function 'agent-shell-status)
                   (lambda (&rest _) 'ready)))
          (agent-shell-cockpit--render)
          (should (agent-shell-cockpit--goto-buffer (nth 1 buffers)))
          (agent-shell-cockpit-refresh)
          (should (eq (agent-shell-cockpit--buffer-at-point)
                      (nth 1 buffers))))))))

(ert-deftest agent-shell-cockpit-refresh-preserves-unfocused-window-session ()
  (agent-shell-cockpit-test--with-buffers '(" alpha" " beta" " cockpit")
    (let* ((cockpit (nth 2 buffers))
           (cockpit-window (selected-window)))
      (delete-other-windows cockpit-window)
      (set-window-buffer cockpit-window cockpit)
      (with-current-buffer cockpit
        (let ((agent-shell-cockpit--buffer cockpit)
              (inhibit-read-only t))
          (cl-letf (((symbol-function 'agent-shell-buffers)
                     (lambda () (seq-take buffers 2)))
                    ((symbol-function 'agent-shell-status)
                     (lambda (&rest _) 'ready)))
            (agent-shell-cockpit--render)
            (should (agent-shell-cockpit--goto-buffer (nth 1 buffers)))
            (agent-shell-cockpit-open)
            (with-current-buffer cockpit
              (goto-char (point-min)))
            (agent-shell-cockpit-refresh)
            (with-current-buffer cockpit
              (should (eq (get-text-property
                           (window-point cockpit-window)
                           'agent-shell-cockpit-buffer)
                          (nth 1 buffers)))))))
      (delete-other-windows cockpit-window))))

(ert-deftest agent-shell-cockpit-kill-removes-selected-buffer ()
  (agent-shell-cockpit-test--with-buffers '(" doomed")
    (let ((session (car buffers))
          (agent-shell-cockpit--buffer (current-buffer))
          (inhibit-read-only t))
      (insert (propertize "session\n" 'agent-shell-cockpit-buffer session))
      (goto-char (point-min))
      (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest _) t))
                ((symbol-function 'agent-shell-cockpit-refresh) #'ignore))
        (agent-shell-cockpit-kill)
        (should-not (buffer-live-p session))))))

(ert-deftest agent-shell-cockpit-opens-session-right-and-keeps-cockpit ()
  (agent-shell-cockpit-test--with-buffers '(" session" " cockpit")
    (let* ((session (nth 0 buffers))
           (cockpit (nth 1 buffers))
           (cockpit-window (selected-window)))
      (delete-other-windows cockpit-window)
      (set-window-buffer cockpit-window cockpit)
      (with-current-buffer cockpit
        (let ((inhibit-read-only t))
          (insert (propertize "session\n" 'agent-shell-cockpit-buffer session))
          (goto-char (point-min)))
        (agent-shell-cockpit-open))
      (should (= (length (window-list)) 2))
      (should (eq (window-buffer cockpit-window) cockpit))
      (should (eq (window-buffer (selected-window)) session))
      (should (> (window-pixel-left (selected-window))
                 (window-pixel-left cockpit-window)))
      (delete-other-windows cockpit-window))))

(ert-deftest agent-shell-cockpit-control-navigation-previews-on-right ()
  (agent-shell-cockpit-test--with-buffers '(" alpha" " beta" " cockpit")
    (let* ((cockpit (nth 2 buffers))
           (cockpit-window (selected-window)))
      (delete-other-windows cockpit-window)
      (set-window-buffer cockpit-window cockpit)
      (with-current-buffer cockpit
        (let ((agent-shell-cockpit--buffer cockpit)
              (inhibit-read-only t))
          (cl-letf (((symbol-function 'agent-shell-buffers)
                     (lambda () (seq-take buffers 2)))
                    ((symbol-function 'agent-shell-status)
                     (lambda (&rest _) 'ready)))
            (agent-shell-cockpit--render)
            (agent-shell-cockpit--goto-first-row)
            (agent-shell-cockpit-preview-next)
            (should (eq (selected-window) cockpit-window))
            (should (eq (window-buffer
                         (window-in-direction 'right cockpit-window))
                        (nth 1 buffers)))
            (should (eq (agent-shell-cockpit--buffer-at-point)
                        (nth 1 buffers))))))
      (delete-other-windows cockpit-window))))

(ert-deftest agent-shell-cockpit-previous-skips-metadata-lines ()
  (agent-shell-cockpit-test--with-buffers
      '(" alpha" " beta" " gamma" " cockpit")
    (let* ((cockpit (nth 3 buffers))
           (cockpit-window (selected-window)))
      (delete-other-windows cockpit-window)
      (set-window-buffer cockpit-window cockpit)
      (with-current-buffer cockpit
        (let ((agent-shell-cockpit--buffer cockpit)
              (inhibit-read-only t))
          (cl-letf (((symbol-function 'agent-shell-buffers)
                     (lambda () (seq-take buffers 3)))
                    ((symbol-function 'agent-shell-status)
                     (lambda (&rest _) 'ready)))
            (agent-shell-cockpit--render)
            (should (agent-shell-cockpit--goto-buffer (nth 2 buffers)))
            (agent-shell-cockpit-preview-previous)
            (should (eq (agent-shell-cockpit--buffer-at-point)
                        (nth 1 buffers)))
            (should (string-match-p
                     "\\[READY\\]"
                     (buffer-substring-no-properties
                      (line-beginning-position) (line-end-position))))
            (agent-shell-cockpit-preview-previous)
            (should (eq (agent-shell-cockpit--buffer-at-point)
                        (nth 0 buffers)))
            (should (string-match-p
                     "\\[READY\\]"
                     (buffer-substring-no-properties
                      (line-beginning-position) (line-end-position)))))))
      (delete-other-windows cockpit-window))))

(ert-deftest agent-shell-cockpit-navigation-wraps-and-recovers-from-metadata ()
  (agent-shell-cockpit-test--with-buffers
      '(" alpha" " beta" " gamma")
    (with-temp-buffer
      (let ((agent-shell-cockpit--selected-buffer nil))
        (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () buffers))
                  ((symbol-function 'agent-shell-status)
                   (lambda (&rest _) 'ready)))
          (agent-shell-cockpit--render)
          ;; Point on a row's metadata still identifies that row, and next
          ;; from the final session wraps to the first one.
          (should (agent-shell-cockpit--goto-buffer (nth 2 buffers)))
          (forward-line 1)
          (should (eq (agent-shell-cockpit--buffer-at-point) (nth 2 buffers)))
          (should (eq (agent-shell-cockpit-next) (nth 0 buffers)))
          ;; Previous from the first session wraps to the final session.
          (should (eq (agent-shell-cockpit-previous) (nth 2 buffers)))
          ;; If point is on non-row text, navigation still has a useful
          ;; origin and selects a session instead of signalling an error.
          (goto-char (point-min))
          (should (eq (agent-shell-cockpit-next) (nth 0 buffers))))))))

(ert-deftest agent-shell-cockpit-navigation-reports-empty-list ()
  (with-temp-buffer
    (cl-letf (((symbol-function 'agent-shell-buffers) (lambda () nil)))
      (should-not (agent-shell-cockpit-next))
      (should-not (agent-shell-cockpit-previous)))))

(ert-deftest agent-shell-cockpit-creates-session-right-and-restores-cockpit ()
  (agent-shell-cockpit-test--with-buffers '(" session" " cockpit")
    (let* ((session (nth 0 buffers))
           (cockpit (nth 1 buffers))
           (cockpit-window (selected-window))
           (sessions nil))
      (delete-other-windows cockpit-window)
      (set-window-buffer cockpit-window cockpit)
      (cl-letf (((symbol-function 'agent-shell-buffers)
                 (lambda () sessions))
                ((symbol-function 'agent-shell-new-shell)
                 (lambda ()
                   (interactive)
                   (setq sessions (list session))
                   (set-window-buffer (selected-window) session)))
                ((symbol-function 'agent-shell-cockpit-refresh) #'ignore))
        (with-current-buffer cockpit
          (agent-shell-cockpit-create)))
      (should (eq (window-buffer cockpit-window) cockpit))
      (should (eq (window-buffer (selected-window)) session))
      (should (> (window-pixel-left (selected-window))
                 (window-pixel-left cockpit-window)))
      (delete-other-windows cockpit-window))))

(ert-deftest agent-shell-cockpit-keeps-evil-motion-keys-free ()
  (dolist (key '("h" "j" "k" "l"))
    (should-not
     (memq (lookup-key agent-shell-cockpit-mode-map (kbd key))
           '(agent-shell-cockpit-next
             agent-shell-cockpit-previous
             agent-shell-cockpit-preview-next
             agent-shell-cockpit-preview-previous))))
  (should (eq (lookup-key agent-shell-cockpit-mode-map (kbd "x"))
              #'agent-shell-cockpit-kill))
  (should (eq (lookup-key agent-shell-cockpit-mode-map (kbd "C-j"))
              #'agent-shell-cockpit-preview-next))
  (should (eq (lookup-key agent-shell-cockpit-mode-map (kbd "C-k"))
              #'agent-shell-cockpit-preview-previous)))

(ert-deftest agent-shell-cockpit-create-bindings-distinguish-default-and-picker ()
  "Lowercase c starts the default agent; uppercase C opens the ACP picker."
  (should (eq (lookup-key agent-shell-cockpit-mode-map (kbd "c"))
              #'agent-shell-cockpit-create))
  (should (eq (lookup-key agent-shell-cockpit-mode-map (kbd "C"))
              #'agent-shell-cockpit-create-new)))

(ert-deftest agent-shell-cockpit-mode-has-no-presentation-dependencies ()
  (with-temp-buffer
    (let ((agent-shell-cockpit-refresh-interval nil))
      (agent-shell-cockpit-mode)
      (should (derived-mode-p 'agent-shell-cockpit-mode))
      (should-not (bound-and-true-p olivetti-mode)))))

(provide 'agent-shell-cockpit-test)

;;; agent-shell-cockpit-test.el ends here
