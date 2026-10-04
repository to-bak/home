;;; post-init.el --- Personal configuration -*- no-byte-compile: t; lexical-binding: t; -*-

;; Reuse the existing Straight installation.
(load (expand-file-name "straight/repos/straight.el/bootstrap.el"
                        user-emacs-directory)
      nil 'nomessage)

;; Use Emacs's bundled use-package with Straight's official integration.
(require 'use-package)
(setq straight-use-package-by-default t
      use-package-always-ensure nil
      use-package-always-defer t)

(setq org-fold-core-style 'overlays)

(defvar host/org-agenda-path (expand-file-name "~/org"))
(defvar host/org-roam-path (expand-file-name "~/org/roam"))
(defvar host/gptel-config nil
  "Optional function configuring GPTel after it loads.")
(defun host/setup-hyperbole-links ()
  "Configure host-specific Hyperbole links; redefine in host.el if needed."
  nil)
(load (expand-file-name "host.el" user-emacs-directory) t 'nomessage)
(defvar host/org-agenda-inbox-path
  (expand-file-name "inbox.org" host/org-agenda-path))
(defvar host/org-agenda-reviews-path
  (expand-file-name "data/reviews.org" host/org-agenda-path))

(load custom-file t 'nomessage)

;; Preserve the original preference for a single minibuffer prompt.
(setq enable-recursive-minibuffers nil)

;; minimal-emacs.d already configures these built-in history settings.
(savehist-mode 1)
(recentf-mode 1)

(load-file (expand-file-name "lisp/setup-orderless.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-vertico.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-consult.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-marginalia.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-embark.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-avy.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-appearance.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-editing.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-dired.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-coding.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-corfu.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-languages.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-project.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-magit.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-shells.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-windows.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-ace-window.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-switchy-window.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-popper.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-transient.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-ai.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-extras.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-elfeed.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-org.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-org-agenda.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-org-roam.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-desktop.el" user-emacs-directory))

(load-file (expand-file-name "lisp/setup-meow.el" user-emacs-directory))
(load-file (expand-file-name "lisp/setup-evil.el" user-emacs-directory))

;;; post-init.el ends here
