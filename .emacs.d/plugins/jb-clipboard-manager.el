;;; jb-clipboard-manager.el --- Consult interface for cliphist  -*- lexical-binding: t; -*-

;;; Commentary:
;; Browse Wayland clipboard history together with the Emacs kill ring.

;;; Code:
(require 'seq)
(require 'subr-x)

(defun jb/get-cliphist-entries ()
  "Return the 50 most recent fully decoded cliphist entries."
  (when (executable-find "cliphist")
    (with-temp-buffer
      (when (= 0 (call-process "cliphist" nil t nil "list"))
        (let ((lines (seq-take (split-string (buffer-string) "\n" t) 50)))
          (delq
           nil
           (mapcar
            (lambda (line)
              (when (string-match "^\\([0-9]+\\)\t" line)
                (let ((id (match-string 1 line)))
                  (with-temp-buffer
                    (when (= 0 (call-process "cliphist" nil t nil "decode" id))
                      (string-trim (buffer-string)))))))
            lines)))))))

(defun jb/clipboard-manager ()
  "Select from cliphist and the kill ring, then copy the full entry."
  (interactive)
  (require 'consult)
  (let* ((items (delete-dups
                 (append (jb/get-cliphist-entries) kill-ring)))
         (candidates
          (mapcar
           (lambda (item)
             (cons (truncate-string-to-width
                    (replace-regexp-in-string "\n" " " item)
                    80 nil nil "...")
                   item))
           items))
         (selected
          (consult--read candidates
                         :prompt "Clipboard history: "
                         :sort nil
                         :require-match t
                         :category 'kill-ring
                         :lookup #'consult--lookup-cdr
                         :history 'consult--yank-history)))
    (when selected
      (with-temp-buffer
        (insert selected)
        (call-process-region (point-min) (point-max) "wl-copy"))
      (unless (member selected kill-ring)
        (kill-new selected))
      (message "Copied to clipboard: %s"
               (truncate-string-to-width selected 50 nil nil "...")))))

(provide 'jb-clipboard-manager)
;;; jb-clipboard-manager.el ends here
