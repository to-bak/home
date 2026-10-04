;;; pre-early-init.el --- Preserve straight.el package management -*- no-byte-compile: t; lexical-binding: t; -*-

;; The upstream init.el can use package.el.  The personal configuration uses
;; straight.el, so avoid package initialization and archive refresh at startup.
(setq minimal-emacs-package-initialize-and-refresh nil)

;; Ace Window adds its label during init. Hiding the native mode line first
;; leaves only that label and prevents minimal-emacs from restoring the rest.
(setq minimal-emacs-disable-mode-line-during-startup nil)

;;; pre-early-init.el ends here
