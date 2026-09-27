;;; development-config.el --- Language and navigation settings -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------
;; Languages
;; ---------------------------------------------------------------------
(use-package elixir-ts-mode
  :straight (:type built-in))
(use-package heex-ts-mode
  :straight (:type built-in))
(use-package haskell-mode)
(use-package cc-mode)
(use-package rust-mode)
(use-package nix-mode)
(use-package markdown-mode)
(use-package erlang)
(use-package protobuf-mode)
(use-package yaml-mode)
(use-package dockerfile-mode)
(use-package docker)
(use-package k8s-mode)

;; Emacs 31 can opt into tree-sitter modes centrally.  Grammars are provided
;; declaratively by Home Manager, so never download or compile them at runtime.
(use-package treesit
  :straight (:type built-in)
  :custom
  (treesit-auto-install-grammar nil)
  (treesit-enabled-modes
   '(bash-ts-mode
     c-ts-mode
     c++-ts-mode
     elixir-ts-mode
     heex-ts-mode
     json-ts-mode
     rust-ts-mode
     yaml-ts-mode)))


;; ---------------------------------------------------------------------
;; Cross reference navigation
;; ---------------------------------------------------------------------
(use-package dumb-jump
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

(setq dumb-jump-rg-search-args "--pcre2 --no-ignore -g '!_build/'")

(provide 'development-config)

;;; development-config.el ends here
