;;; ws-tools.el --- websocket tools -*- lexical-binding: t -*-

;;; Commentary:
;; Tools to handle websocket connection with overlay application

;;; Code:
(require 'websocket)
(require 'posframe)

(defvar ws--client nil)
(defvar ws--ping-timer nil)

(setq ws--url "ws://localhost:5555/socket/websocket")

(defun ws-setup-all ()
  "Start connection and perform some actions required to work properly."
  (interactive)
  (let* ((socket (ws--create-new-connection)))
    (setq ws--client socket)
    ;; we need to send this message to subscribe emacs channel
    ;; and receive messages from server
    (ws--send-join socket)
    ;; send a ping after 1 second and repeat every 5 seconds
    (setq ws--ping-timer (run-with-timer 1 5 #'(lambda () (ws--send-ping ws--client))))))

(defun ws-stop-all ()
  "Stop all websocket execution."
  (interactive)
  (cancel-timer ws--ping-timer)
  (when (websocket-openp ws--client)
    (websocket-close ws--client)))

(defun ws--create-new-connection ()
  "Create a new websocket connection and configure it."
  (websocket-open
   ws--url
   :on-message 'ws--on-message
   :on-close (lambda (_websocket) (message "Connection closed"))))

(defun ws--send-message (socket message)
  "Send MESSAGE if SOCKET is still open."
  (unless (websocket-openp socket)
    (user-error "Websocket is closed"))
  (websocket-send-text socket message))

(defun ws--enable-light-theme (restart-after user)
  "Change theme to a light one and restore current theme after RESTART-AFTER secs.
Also show USER who activate this feature."
  (disable-theme 'dracula)
  (load-theme 'modus-operandi t)
  (message "%s used light theme" user)
  (run-with-timer restart-after nil #'(lambda ()
                                       (disable-theme 'modus-operandi)
                                       (load-theme 'dracula t))))

(defun ws--highlight-line (start text)
  "Highlight a line in current buffer using START position and show TEXT as a tooltip."
  (when (and (> start 0) (<= start (count-lines (point-min) (point-max))))
    (goto-line start)
    (goto-char (line-beginning-position))
    (push-mark)
    (goto-char (line-end-position))
    (activate-mark)
    (if (and (stringp text) (not (string-equal text "")))
        (progn
          ;; enable bell sound just at this scope
          (let ((ring-bell-function nil))
            (ding))
          ;; show visual bell just for this scope
          (let ((ring-bell-function nil)
                (visible-bell t))
            (ding))
          ;; show tooltip for 10 seconds
          ;; set nil and nil to use default position and current window
          (posframe-show "*line-toolip*" :string text
                         :border-width 3
                         :left-fringe 10
                         :right-fringe 10
                         :border-color "red"
                         :position (point))
          (run-with-timer 5 nil #'(lambda ()
                                    (posframe-delete "*line-toolip*")))))))

(defun ws--change-font (font-name restart-after)
  "Change font family using FONT-NAME and restart to default value after RESTART-AFTER seconds."
  (set-frame-font (format "%s %d" font-name 26))
  (run-with-timer restart-after nil #'(lambda ()
                             (set-frame-font (format "%s %d" "JetBrainsMono Nerd Font" 26)))))

(defun ws--on-message (_websocket frame)
  "Receive FRAME from websocket connection."
  (let* ((raw-string (websocket-frame-text frame))
         (table (json-parse-string raw-string)))
    (ws--process-message table)))

(defun ws--play-game (game)
  "Launch received GAME."
  (funcall (intern game)))

(defun ws--process-message (message)
  "Process MESSAGE and execute code depending of its value."
  (let ((event (gethash "event" message))
        (payload (gethash "payload" message)))
    (cond ((string-equal event "light-theme") (ws--enable-light-theme 10 (gethash "user" payload)))
          ((string-equal event "line") (ws--highlight-line (gethash "start" payload) (gethash "text" payload)))
          ((string-equal event "minecraft") (ws--change-font "Monocraft" 10))
          ((string-equal event "game") (ws--play-game (gethash "game" payload)))
          ;TODO: add a loader for burn.el package
          ((string-equal event "burn") (burn-code))
          ;; ignore replies, we only listen to specific events sent by server
          ((string-equal event "phx_reply") nil)
          (t (message "Received: %s" (json-encode message))))))

(defun ws--build-message (event)
  "Build a websocket message with the given EVENT."
  (let* ((table (make-hash-table)))
    (puthash 'topic "emacs:lobby" table)
    (puthash 'event event table)
    ;;TODO: generate a unique ref
    (puthash 'ref "unique" table)
    ;; always use a empty payload, we're not going to send different message
    (puthash 'payload (make-hash-table) table)
    (json-encode table)))

(defun ws--send-ping (socket)
  "Send a ping message to SOCKET to keep connection alive."
  (when (websocket-openp socket)
    (ws--send-message socket (ws--build-message "ping"))))

(defun ws--send-join (socket)
  "Send a message using SOCKET to join phoenix channel topic."
  (when (websocket-openp socket)
    (ws--send-message socket (ws--build-message "phx_join"))))

(provide 'ws-tools)
;;; ws-tools.el ends here
