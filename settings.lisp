(load "common-defs.lisp")

;; Need to know at least nick and serv
(defparameter *login*
  (make-login-info
   :nick "robort"
   :server "irc.tamu.edu"))

(defparameter *servers*
  '("#bottest"))