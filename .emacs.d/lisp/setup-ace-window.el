;;; setup-ace-window.el --- Select windows by label -*- lexical-binding: t; -*-

(use-package ace-window
  :demand t
  :bind ("C-x o" . ace-window)
  :config
  (setq aw-keys '(?q ?w ?e ?r ?t ?y ?u ?i ?p)
        aw-scope 'global
        aw-background nil
        aw-dispatch-always t
        aw-display-mode-overlay nil
        aw-swap-invert t)

  ;; Karthink's action keys, using the package's own commands.
  (setq aw-dispatch-alist
        '((?k aw-delete-window "Delete window")
          (?x aw-swap-window "Swap windows")
          (?m aw-move-window "Move window")
          (?c aw-copy-window "Copy window")
          (?j aw-switch-buffer-in-window "Select buffer")
          (?b aw-switch-buffer-other-window "Buffer in other window")
          (?s aw-split-window-vert "Split below")
          (?v aw-split-window-horz "Split right")
          (?= aw-split-window-fair "Split fairly")
          (?o delete-other-windows "Keep selected window")
          (?? aw-show-dispatch-help)))
  (put 'ace-window 'repeat-map 'other-window-repeat-map)
  (ace-window-display-mode 1))

;;; setup-ace-window.el ends here
