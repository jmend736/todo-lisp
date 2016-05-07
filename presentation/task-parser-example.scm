#!/bin/bash
source /Users/gmgilmore/.bash_profile
mit-scheme-script /Users/gmgilmore/dev/todo-lisp/presentation/task-parser-example.scm

exit
(cd "../")
(load "load.scm")
(cd "presentation/")
;;START OMIT

(pp (reader:read-tasks "test.txt" "#!" "--BEGIN--"))

;;END OMIT
