;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;                               todo-lisp
;;
;; Filename: io.scm
;;
;; Description:
;;          Function to write to a dot file and run dot
;;
;; Functions:
;;          (write-dot-file [string] [filename]) ~ See above
;;
;;
;; Author: jmend
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load-option 'synchronous-subprocess)

;; Procedure used to write to a .dot file
;; and also run dot to process it

(define (write-dot-file str filename)
  (let ((file-port (open-output-file (string-append filename ".dot"))))
    (write-string str file-port)
    (flush-output file-port)
    (let ((port (open-output-string)))
      (and (= (run-shell-command (string-append "dot -Tps "
                                                (string-append filename ".dot")
                                                " -o "
                                                (string-append filename ".ps"))
                                 'output port))
           0)
      (get-output-string port))))


