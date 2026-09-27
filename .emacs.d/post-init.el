;;; post-init.el --- Personal Emacs configuration -*- no-byte-compile: t; lexical-binding: t; -*-

;; Personal modules and local libraries.
(add-to-list 'load-path (expand-file-name "lisp/" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp/custom/" user-emacs-directory))


;; ---------------------------------------------------------------------
;; Package management
;; ---------------------------------------------------------------------
;; Straight packages can be noisy under a new Emacs compiler.  Suppress both
;; native- and byte-compiler warning logs while leaving other warning classes
;; visible at `warning-minimum-level'.
(require 'warnings)
(dolist (type '((native-compiler) (bytecomp)))
  (add-to-list 'warning-suppress-types type)
  (add-to-list 'warning-suppress-log-types type))

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package with straight.el
(straight-use-package 'use-package)

;; Install packages by default in `use-package` forms,
;; without having to specify `:straight t`
(setq straight-use-package-by-default t)


;; ---------------------------------------------------------------------
;; host.el
;; ---------------------------------------------------------------------
(defvar host/org-agenda-path "~/org"
  "Default path for Org agenda. Overridden by host.el if present.")

(defvar host/org-roam-path "~/org/roam"
  "Default path for Org agenda. Overridden by host.el if present.")

(defun host/setup-hyperbole-links ()
  "Initialize machine-specific Hyperbole links."
  nil)

(defvar host/gptel-config nil
  "Function that configures gptel for the current host.
It is called after gptel has loaded.  Define it in host.el when this machine
has gptel backends or settings of its own.")

(defvar host/agent-shell-config nil
  "Function that configures agent-shell for the current host.
It is called after agent-shell has loaded.  Define it in host.el when this
machine has agent-specific commands, models, or other settings.")

(load (expand-file-name "host.el" user-emacs-directory) t)

(defvar host/org-agenda-ticket-path (concat host/org-agenda-path "/tickets")
  "Default path for Org agenda. Overridden by host.el if present.")

(defvar host/org-agenda-inbox-path (concat host/org-agenda-path "/inbox.org")
  "Default path for Org agenda. Overridden by host.el if present.")

(defvar host/org-agenda-reviews-path (concat host/org-agenda-path "/data/reviews.org")
  "Default path for Org agenda. Overridden by host.el if present.")


;; ---------------------------------------------------------------------
;; Local customizations
;; ---------------------------------------------------------------------
(load custom-file t)


;; ---------------------------------------------------------------------
;; Emacs-wide behavior
;; ---------------------------------------------------------------------
;; Keep minibuffer prompts single-level, including with Vertico enabled.
(setq enable-recursive-minibuffers nil)

;; Clean up whitespace whenever a buffer is saved.
(add-hook 'before-save-hook #'whitespace-cleanup)


;; Load personal modules after the baseline setup.
(require 'misc-config)
(require 'appearance-config)
(require 'desktop-config)
(require 'completion-config)
(require 'evil-config)
(require 'version-control-config)
(require 'development-config)
(require 'org-config)
(require 'terminal-config)
(require 'ai-tooling-config)

;;; post-init.el ends here
