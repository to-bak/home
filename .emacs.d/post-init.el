;;; post-init.el --- Select desktop or phone profile -*- lexical-binding: t; -*-

;; Set EMACS_PROFILE explicitly to try a profile on another machine.
(defvar obp/emacs-profile
  (or (getenv "EMACS_PROFILE")
      (if (or (getenv "TERMUX_VERSION")
              (string-prefix-p "/data/data/com.termux/"
                               (or (getenv "PREFIX") "")))
          "phone"
        "desktop")))

(load (expand-file-name "lisp/setup-packages.el" user-emacs-directory)
      nil 'nomessage)

(pcase obp/emacs-profile
  ("phone"
   (load (expand-file-name "lisp/setup-phone.el" user-emacs-directory)
         nil 'nomessage))
  ("desktop"
   (load (expand-file-name "lisp/setup-desktop-profile.el" user-emacs-directory)
         nil 'nomessage))
  (_ (error "Unknown EMACS_PROFILE: %s" obp/emacs-profile)))

;;; post-init.el ends here
