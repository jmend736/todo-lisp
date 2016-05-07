#!/bin/bash
source /Users/gmgilmore/.bash_profile
mit-scheme-script /Users/gmgilmore/dev/todo-lisp/presentation/error-handling-parser.scm
exit

(cd "../")
(load "load.scm")
(cd "presentation/")
;;START OMIT

(pp (reader:read-tasks "broken-test.txt" "#!" "--BEGIN--"))

;;END OMIT
