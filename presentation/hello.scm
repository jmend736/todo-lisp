#!/bin/bash
source /Users/gmgilmore/.bash_profile
mit-scheme-script /Users/gmgilmore/dev/todo-lisp/presentation/hello.scm
exit
;;START OMIT

(define hello-er (lambda (x)
		   (if (eq? 0 (string-length x))
		       "Hello, world!"
		       (string-append "Hello, " x))))
      
(pp (hello-er "GG"))

(pp (hello-er ""))
;;END OMIT

