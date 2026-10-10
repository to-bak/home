;;; setup-packages.el --- Shared Straight and use-package setup -*- lexical-binding: t; -*-

;; Reuse existing installations, or bootstrap a fresh checkout (e.g. Termux).
;; This is Straight's documented bootstrap snippet.
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         (or (bound-and-true-p straight-base-dir)
                             user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (require 'url)
    (let ((buffer
           (url-retrieve-synchronously
            "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
            'silent 'inhibit-cookies)))
      (unless buffer
        (error "Could not download Straight installer; check the network connection"))
      (with-current-buffer buffer
        (goto-char (point-max))
        (eval-print-last-sexp))))
  (load bootstrap-file nil 'nomessage))

(require 'use-package)
(setq straight-use-package-by-default t
      use-package-always-ensure nil
      use-package-always-defer t)

;;; setup-packages.el ends here
