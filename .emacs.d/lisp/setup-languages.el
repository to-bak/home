;;; setup-languages.el --- Language modes and Tree-sitter -*- lexical-binding: t; -*-

(use-package treesit
  :straight nil
  :demand t
  :config
  ;; Home Manager supplies grammars through site-start.
  (setq treesit-auto-install-grammar nil)
  ;; The custom setter installs native major-mode remappings.
  (setopt treesit-enabled-modes
          '(bash-ts-mode c-ts-mode c++-ts-mode c-or-c++-ts-mode
            elixir-ts-mode heex-ts-mode json-ts-mode rust-ts-mode
            yaml-ts-mode dockerfile-ts-mode)))

;; Straight installs autoloads and file associations for these modes.
(use-package haskell-mode)
(use-package rust-mode)
(use-package nix-mode)
(use-package markdown-mode)
(use-package erlang)
(use-package protobuf-mode)
(use-package yaml-mode)
(use-package dockerfile-mode)
(use-package k8s-mode)

;;; setup-languages.el ends here
