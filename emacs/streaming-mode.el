;;; streaming-mode.el --- Tools for streaming

;;; Commentary:
;; Collection of tools to integrate Emacs with elixir overlay application

;;; Code:

(require 'erc)

(defcustom streaming-mode--font-family "Iosevka"
  "Font used for streaming."
  :type 'string
  :group 'streaming-mode)

(defcustom streaming-mode--overlay-url "http://localhost:5555/api/overlay"
  "Overlay endpoint to send notifications."
  :type 'string
  :group 'streaming-mode)

(defvar streaming-mode--big-font-mode-tmp)

(define-minor-mode streaming-mode--big-font-mode
  "Switch between a regular font size and a presentation font size."
  :init-value nil
  :global t
  :group 'streaming-mode
  (if streaming-mode--big-font-mode
      (progn
        ;; save current font size in a temp variable to be able to restore it
        ;; after this minor mode is disabled
        (setq streaming-mode--big-font-mode-tmp (/ (face-attribute 'default :height) 10))
        (set-face-attribute 'default nil :font (format "%s 26" streaming-mode--font-family)))
    (set-face-attribute 'default nil :font (format "%s %d" streaming-mode--font-family streaming-mode--big-font-mode-tmp))))

(defun streaming-mode--event-post (event-name)
  "Make POST request using 'EVENT-NAME' to notify overlay application."
  (let ((url-request-method "POST")
        (url-request-extra-headers `(("Content-Type" . "application/json")))
        (url-request-data (format "{\"event\": \"%s\"}" event-name)))
    (url-retrieve streaming-mode--overlay-url (lambda (status) nil))))

(defun streaming-mode--notify-overlay (_buffer result)
  "Check compilation RESULT and trigger a event for each case."
  (if (string-match "^finished" result)
      (streaming-mode--event-post "exit_zero")
    (streaming-mode--event-post "exit_non_zero")))

(define-minor-mode streaming-mode
  "Configuration for streaming."
  :init-value nil
  :lighter "Streaming mode"
  :global t
  :group 'streaming-mode
  (if streaming-mode
      (progn
        (add-to-list 'compilation-finish-functions 'streaming-mode--notify-overlay)
        (global-display-line-numbers-mode)
        (streaming-mode--big-font-mode))
    (progn
      (setq compilation-finish-functions (delq 'streaming-mode--notify-overlay compilation-finish-functions))
      (streaming-mode--big-font-mode -1))))

(defun streaming-mode-setup-twitch-irc ()
  "Setup ERC variables to connect to twitch IRC server."
  (interactive)
  (setq erc-server "irc.chat.twitch.tv"
        erc-nick "erickgnavar"
        erc-password (read-passwd "Enter Twitch IRC token: ")))

(provide 'streaming-mode)

;;; streaming-mode.el ends here
