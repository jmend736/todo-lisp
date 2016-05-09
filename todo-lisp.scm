;; This is the main file which provides a function to specify a filename and
;; output a schedule.  It also automatically runs itself with "sample.txt".

(define (todo-lisp filename)
  (define parsed-file (reader:read-tasks filename "#!" reader:task-separator))
  (pp parsed-file)
  (sched:set-options (car parsed-file))
  (sched:make-tasks (cdr parsed-file))
  (define final-schedule (sched:get-schedule))
  (pp final-schedule))
    ; (define format)
    ; ((d:factory format) final-schedule)))


(todo-lisp "sample.txt")