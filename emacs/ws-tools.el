;;; ws-tools.el --- websocket tools

;;; Commentary:
;; Tools to handle websocket connection with overlay application

;;; Code:
(require 'websocket)

(defvar ws--client nil)
(defvar ws--ping-timer nil)

(setq ws--url "ws://localhost:4000/socket/websocket")

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

(defun ws--enable-light-theme (restart-after)
  "Change default theme to a light one and restore previous theme after RESTART-AFTER seconds."
  (disable-theme 'dracula)
  (load-theme 'modus-operandi t)
  (run-with-timer restart-after nil #'(lambda ()
                                       (disable-theme 'modus-operandi)
                                       (load-theme 'dracula t))))

(defun ws--on-message (_websocket frame)
  "Receive FRAME from websocket connection."
  (let* ((raw-string (websocket-frame-text frame))
         (table (json-parse-string raw-string)))
    (ws--process-message table)))

(defun ws--process-message (message)
  "Process MESSAGE and execute code depending of its value."
  (let ((event (gethash "event" message)))
    (cond ((string-equal event "light-theme") (ws--enable-light-theme 5))
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
