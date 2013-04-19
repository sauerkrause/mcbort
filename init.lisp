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
(require :cl-irc)

(load "common-defs.lisp")
(load "user-commands.lisp")
(load "user-commands/reload.lisp")
(defun init-hooks (connection)
  (irc:add-hook connection 'irc::irc-privmsg-message
		(handle-command connection)))
  	    ;; #'(lambda (msg)
	    ;; 	(print msg)
  	    ;; 	(error 'reload-required))))

;; Do anything that needs to be done prior to reading the loops here.
(defun init (connection)
  (progn
    ;; Maybe connect to the channels we want here.
    (dolist (s *channels*)
	      (irc:join connection s))
    ;; Maybe initialize some hooks.
    (init-hooks connection)))
