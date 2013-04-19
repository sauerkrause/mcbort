;;     This file is part of Robort.

;;     Robort is free software: you can redistribute it and/or modify
;;     it under the terms of the GNU General Public License as published by
;;     the Free Software Foundation, either version 3 of the License, or
;;     (at your option) any later version.

;;     Robort is distributed in the hope that it will be useful,
;;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;     GNU General Public License for more details.

;;     You should have received a copy of the GNU General Public License
;;     along with Robort.  If not, see <http://www.gnu.org/licenses/>.
(ql:quickload "cl-irc")

(require :cl-irc)

(load "settings.lisp")
(load "common-defs.lisp")
(load "init.lisp")

;; need this as *logins* should be closed over for this.
(defun get-connection (login)
  (progn
    (print (login-info-nick login))
    (print (login-info-server login))
    (irc:connect
     :server (login-info-server login)
     :nickname (login-info-nick login))))

(defun reload (connection)
  (progn
    ;; Use quit, not die or disconnect.
    (irc:quit connection)
    (print "Died connection hopefully")))

;; Entry point
(defun main ()
  (progn
    (load "settings.lisp")
    (load "common-defs.lisp")
    (load "init.lisp")
    (let ((connection (get-connection *login*)))
      (handler-case
       (progn
	 (init connection)
	 (irc:read-message-loop connection))
       (reload-required () (reload connection))))))

(loop
 (main))
