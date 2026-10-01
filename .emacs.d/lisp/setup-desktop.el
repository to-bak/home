;;; setup-desktop.el --- Personal Emacs settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Desktop integration
;; ---------------------------------------------------------------------
(use-package emacs-everywhere
  :commands emacs-everywhere
  :custom
  (emacs-everywhere-frame-parameters
   '((name . "emacs-everywhere")
     (minibuffer . t)
     (fullscreen . nil)
     (width . 100)
     (height . 24)))
  :config
  ;; i3 owns placement.  The package default moves the frame next to the
  ;; pointer after i3 has centered it, which can leave it partly off-screen.
  (remove-hook 'emacs-everywhere-init-hooks
               #'emacs-everywhere-set-frame-position))

(use-package universal-launcher
  :straight nil
  :load-path "lisp/custom"
  :custom
  (universal-launcher-bookmarks-file
   (expand-file-name "bookmarks.org" host/org-agenda-path))
  :commands universal-launcher-popup)

(use-package desktop-emacs-popups
  :straight nil
  :load-path "lisp/custom"
  :commands (obp/desktop-universal-launcher
             obp/desktop-org-capture
             obp/desktop-org-roam-capture
             obp/desktop-org-roam-daily-capture))

;;; setup-desktop.el ends here
