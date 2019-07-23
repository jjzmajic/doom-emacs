;;; emacs/vc/config.el -*- lexical-binding: t; -*-

(when IS-WINDOWS
  (setenv "GIT_ASKPASS" "git-gui--askpass"))


(setq vc-make-backup-files nil
      vc-follow-symlinks t)


(after! git-timemachine
  ;; HACK Waiting for https://gitlab.com/pidu/git-timemachine/issues/77
  (def-advice! +vc-git-timemachine-show-commit-a ()
    "Fix `git-timemachine-show-commit'."
    :override #'git-timemachine-show-commit
    (interactive)
    (let ((rev (car git-timemachine-revision)))
      (if (fboundp 'magit-revision-mode)
          (with-temp-buffer
            (save-excursion
              (magit-setup-buffer #'magit-revision-mode nil
                (magit-buffer-revision rev)
                (magit-buffer-range (format "%s^..%s" rev rev))
                (magit-buffer-diff-args nil)
                (magit-buffer-diff-files nil))))
        (message "You need to install magit to show commit"))))

  ;; Sometimes I forget `git-timemachine' is enabled in a buffer, so instead of
  ;; showing revision details in the minibuffer, show them in
  ;; `header-line-format', which has better visibility.
  (setq git-timemachine-show-minibuffer-details t)
  (advice-add #'git-timemachine--show-minibuffer-details
              :override #'+vc-update-header-line-a)

  (after! evil
    ;; rehash evil keybindings so they are recognized
    (add-hook 'git-timemachine-mode-hook #'evil-normalize-keymaps))

  (when (featurep! :tools magit)
    (add-transient-hook! #'git-timemachine-blame (require 'magit-blame)))

  (map! :map git-timemachine-mode-map
        :n "gtc" #'git-timemachine-show-commit))


;;;###package git-commit
(use-package! git-commit
  :after-call after-find-file
  :config
  (global-git-commit-mode +1)
  (set-yas-minor-mode! 'git-commit-mode)

  (add-hook 'git-commit-mode-hook
    (defun +vc-enforce-git-commit-conventions-h ()
      "See https://chris.beams.io/posts/git-commit/"
      (setq fill-column 72
            git-commit-summary-max-length 50
            git-commit-style-convention-checks '(overlong-summary-line non-empty-second-line))))

  (add-hook 'git-commit-setup-hook
    (defun +vc-start-in-insert-state-maybe ()
      "Start git-commit-mode in insert state if in a blank commit message,
otherwise in default state."
      (when (and (bound-and-true-p evil-mode)
                 (bobp) (eolp))
        (evil-insert-state)))))

(after! vc-annotate
  (set-popup-rules!
    '(("^\\vc-d" :select nil) ; *vc-diff*
      ("^\\vc-c" :select t))) ; *vc-change-log*
  (set-evil-initial-state!
    '(vc-annotate-mode vc-git-log-view-mode)
    'normal))

(after! smerge-mode
  (unless EMACS26+
    (with-no-warnings
      (defalias #'smerge-keep-upper #'smerge-keep-mine)
      (defalias #'smerge-keep-lower #'smerge-keep-other)
      (defalias #'smerge-diff-base-upper #'smerge-diff-base-mine)
      (defalias #'smerge-diff-upper-lower #'smerge-diff-mine-other)
      (defalias #'smerge-diff-base-lower #'smerge-diff-base-other))))

