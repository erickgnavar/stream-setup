# Alfred

Application with utilities for OBS stream

## Overlay

This is a liveview page in `/overlay` which can be loaded in OBS using web browser source

We can connect emacs with this overlay by using the following code

```emacs-lisp
(defun my/stream-event-post (event-name)
  "Make POST request to notify overlay application about new event."
  (let ((url-request-method "POST")
        (url-request-extra-headers `(("Content-Type" . "application/json")))
        (url-request-data (format "{\"event\": \"%s\"}" event-name)))
    (url-retrieve-synchronously "http://localhost:4000/api/overlay" t)))

(defun my/notify-stream (buffer result)
  "Check compilation result and trigger a event for each case."
  (if (string-match "^finished" result)
      (my/stream-event-post "exit_zero")
    (my/stream-event-post "exit_non_zero")))

(add-to-list 'compilation-finish-functions 'my/notify-stream)
```

This will point to a instance of the application running in localhost
