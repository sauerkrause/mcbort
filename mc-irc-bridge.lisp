;; Copyright 2013 Robert Allen Krause <robert.allen.krause@gmail.com>

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

(in-package :mcirc)

(load "configs/mc.lisp")

(defun follow-log (filename fn)
  (let ((hit-end ()))
    (with-open-file (s filename :direction :input)
      (loop for line = (read-line s nil)
	 while T do (if line 
			(if hit-end
			    (funcall fn line)) 
			(progn (setf hit-end T)
			       (sleep 0.5)))))))

(defun handle-line (line)
  (let ((message ()))
    (when (search "[INFO] <" line)
      (setf message (format nil "~a~%" (subseq line
					       (+ (length "[INFO] ") 
						  (search "[INFO] " line))))))
    (dolist (chan robort::*channels*)
      (when message 
	(irc:privmsg robort::*connection*
		     chan message)))))

(defun start-bridge (connection)
  (sb-thread:make-thread
   (lambda () (follow-log *server-log* #'handle-line))))

(defparameter *thread* ())