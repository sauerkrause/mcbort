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
(require :bordeaux-threads)
(require :cl-ppcre)

(in-package :mcirc)

(load "configs/mc.lisp")

(defun follow-log (filename fn server-name)
  (let ((hit-end ()))
    (with-open-file (s filename :direction :input)
      (loop for line = (read-line s nil)
	 while T do (progn 
		      (if line 
			(if hit-end
			    (funcall fn line server-name))
			(progn (setf hit-end T)
			       (sleep 0.5))))))))

(defun death-messagep (line)
  (let ((death-messages
	 (list
	  " was"
	  " got"
	  " walked"
	  " drowned"
	  " hit"
	  " fell"
	  " went"
	  " tried"
	  " burned"
	  " starved"
	  " suffocated"
	  " withered")))
    (and (not (search "[Rcon]" line))
	 (some 
	  (lambda (str) 
	    (search str line)) 
	  death-messages))))

(defun handle-translatable-component (line)
  (let* ((no-ts (cl-ppcre:regex-replace "^[0-9 \:-]*" line ""))
	 (no-info (subseq no-ts 
			  (+ (length "[INFO] TranslatableComponent")
			     (search "[INFO] TranslatableComponent" no-ts))))
	 (message-type ())
	 (message (let ((begin (cl-ppcre:scan "args=\\[" no-info)))
		    (flet ((get-args (str)
				     (format nil "~a" (subseq str
                                                 (+ begin (length "args=\\[") -1)
                                                 (cl-ppcre:scan "\\], " str :start begin)))))
			  (cond
			   ((search "'chat.type.text'" no-info)
			    (progn
			      (setf message-type 'text)
			      (get-args no-info)))
			   ((search "'chat.type.emote'" no-info)
			    (progn
			      (setf message-type 'emote)
			      (get-args no-info)))))))
	 (args (cl-ppcre:split ", " message :limit 2)))
    (if (and args message-type)
	(let ((format-str
	       (case message-type
		     ('text "<~a> ~a")
		     ('emote "* ~a ~a"))))
	  (format nil format-str (car args) (cadr args))))))

(defun handle-line (line server)
  (let ((message ())
	(notice ()))
    (cond ((search "TranslatableComponent" line)
	   (princ line)
	   (let ((msg (handle-translatable-component line)))
	     (if msg
		 (setf message (format nil "~a~%" msg)))))
	  ((search "[INFO] <" line)
	   (setf message (format nil "~a~%" (subseq line
						    (+ (length "[INFO] ") 
						       (search "[INFO] " line))))))
	  ((search "[INFO] *" line)
	   (setf message (format nil "~a~%" (subseq line
						    (+ (length "[INFO] ")
						       (search "[INFO] " line))))))
	  ((and (search "[INFO] " line)
		(search "] logged in with entity" line))
	   (setf notice (format nil "~a has joined~%" 
				(let* ((name-begin
					(+ (length "[INFO] ")
					   (search "[INFO] " line)))
				       (name-end 
					(search "[" line :start2 name-begin)))
				  (subseq line name-begin name-end)))))
	  ((and (search "[INFO] " line)
		(search " lost connection: " line))
	   (setf notice (format nil "~a has quit~%"
				(let* ((name-begin
					(+ (length "[INFO] ")
					   (search "[INFO] " line)))
				       (name-end
					(search " lost connection: " line
						:start2 name-begin)))
				  (subseq line name-begin name-end)))))
	  ((and (search "[INFO] " line)
		(death-messagep line))
	   (setf notice (format nil "~a~%" 
				(let* ((name-begin
					(+ (length "[INFO] ")
					   (search "[INFO] " line))))
				  (subseq line name-begin))))))						  
    (dolist (chan robort::*channels*)
      (flet ((bridge (fn arg)
	       (funcall fn robort::*connection*
			chan (format nil "~a: ~a" server arg))))
      (when message 
	(bridge #'irc:privmsg message))
      (when notice
	(bridge #'irc:notice notice))))))

(defun start-bridge (connection servers)
  (mapcar 
   (lambda (server)
     (bordeaux-threads:make-thread
      (lambda () (follow-log 
		  (robort::mc-server-log-location server) 
		  #'handle-line 
		  (robort::mc-server-server-name server)))))
   servers))

(defparameter *thread* ())
