;;; setup-transient.el --- Window command menu -*- lexical-binding: t; -*-

(use-package transient
  :demand t
  :bind ("C-c w" . obp/window-menu)
  :config
  (require 'windmove)

  (transient-define-prefix obp/window-menu ()
    "Select, arrange, and resize windows; undo layout changes."
    [["Select"
      ("h" "Left" windmove-left :transient t)
      ("j" "Below" windmove-down :transient t)
      ("k" "Above" windmove-up :transient t)
      ("l" "Right" windmove-right :transient t)
      ("o" "Recent window" switchy-window :transient t)
      ("a" "Select by label" ace-window)]
     ["Arrange"
      ("2" "Split below" split-window-below)
      ("3" "Split right" split-window-right)
      ("1" "Maximize/restore" obp/window-toggle-maximize)
      ("d" "Close selected" obp/delete-window-or-tab)
      ("=" "Balance" balance-windows :transient t)]
     ["Resize"
      ("H" "Narrower" shrink-window-horizontally :transient t)
      ("J" "Shorter" shrink-window :transient t)
      ("K" "Taller" enlarge-window :transient t)
      ("L" "Wider" enlarge-window-horizontally :transient t)]]
    [["Buffer zoom"
      ("+" "Increase" text-scale-increase :transient t)
      ("-" "Decrease" text-scale-decrease :transient t)
      ("0" "Reset" (lambda () (interactive) (text-scale-adjust 0)) :transient t)]
     ["Global zoom"
      ("C-+" "Increase" (lambda () (interactive) (global-text-scale-adjust 1)) :transient t)
      ("C--" "Decrease" (lambda () (interactive) (global-text-scale-adjust -1)) :transient t)
      ("C-0" "Reset" (lambda () (interactive) (global-text-scale-adjust 0)) :transient t)]
     ["Layouts"
      ;; Close the menu before restoring a previous layout.
      ("u" "Undo layout" winner-undo)
      ("U" "Redo layout" winner-redo)]]
    [("q" "Quit" transient-quit-one)]))

;;; setup-transient.el ends here
