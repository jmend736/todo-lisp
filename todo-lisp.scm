;; This is the main file which provides a function to specify a filename and
;; output a schedule.  It also automatically runs itself with "sample.txt".

(define (todo-lisp input-filename output-filename)
  (define parsed-file 
    (reader:read-tasks input-filename "#!" reader:task-separator))
  (sched:set-options (car parsed-file))
  (sched:make-tasks (cdr parsed-file))
  (define final-schedule (sched:get-schedule))
  (write-dot-file 
   ((d:factory final-format) final-schedule output-filename) output-filename)
  (d:make-time-subgraph final-schedule))


