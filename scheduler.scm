;; TITLE: scheduler.scm
;; AUTHOR: John O'Sullivan <johno@mit.edu>

;; This file contains the code to create tasks, schedule them into a series of
;; work blocks, and then return a sequential list of all scheduled work blocks.

;;;;;;;;;;;;
;;
;; INTERNAL CONSTANTS
;;
;;;;;;;;;;;;

(define current-time
  (let ((now (universal-time->local-decoded-time (get-universal-time))))
  `(instant ,(make-decoded-time 
	      0
	      0
	      9
	      (decoded-time/day now)
	      (decoded-time/month now)
	      (decoded-time/year now)))))

; (define current-time
;   (let ((decoded-instant 
; 	 (universal-time->local-decoded-time (get-universal-time))))
;   '(instant decoded-instant)))

;; Given some instant, return an instant which is on the next day at 9am.
(define (get-next-day some-time)
  (let ((tomorrow-time (t:+ some-time '(duration 1 0 0) )))
    `(instant ,(make-decoded-time
	       0
	       0
	       9
	       (decoded-time/day (cadr tomorrow-time))
	       (decoded-time/month (cadr tomorrow-time))
	       (decoded-time/year (cadr tomorrow-time))))))

(define daily-time-remaining `(duration 0 8 0))
(define duration-until-break `(duration 0 3 0))
(define options (make-eq-hash-table))
(define completed-tasks (make-eq-hash-table))
(define available-tasks (make-eq-hash-table))
(define blocked-tasks (make-eq-hash-table))
(define all-tasks (make-eq-hash-table))
(define last-allocated-block (make-eq-hash-table))
(define schedule '())

;;;;;;;;;;;;
;;
;; TASK, BLOCK, & OPTION ACCESSORS
;;
;;;;;;;;;;;;

(define (task-id task) (cadr (assv 'id task)))
(define (task-desc task) (cadr (assv 'description task)))
(define (task-deadline task) (cadr (assv 'deadline task)))
(define (task-duration task) (cadr (assv 'duration task)))
(define (task-dependencies task) (cadr (assv 'dependencies task)))
(define (block-id block) (cadr (assv 'block-id block)))
(define (block-start-time block) (cadr (assv 'start-time block)))

(define (get-option name)
  (hash-table/lookup
   options
   name
   (lambda (value) value)
   (lambda () (error "Looked for an option which wasn't present: "
		     (error-irritant/noise name)))))

;;;;;;;;;;;;
;;
;; DEFAULT OPTION VALUES
;;
;;;;;;;;;;;;

(hash-table/put! options 'daily-task-duration `(duration 0 4 0))
(hash-table/put! options 'work-per-day-of-week 
		 (list `(duration 0 8 0)
		       `(duration 0 8 0)
		       `(duration 0 5 0)
		       `(duration 0 3 0)
		       `(duration 0 2 0)
		       `(duration 0 0 0)
		       `(duration 0 0 0)))
(hash-table/put! options 'tool-duration `(duration 0 3 0))
(hash-table/put! options 'punt-duration `(duration 0 0 15))

;;;;;;;;;;;;
;;
;; SETUP CODE: Reads in from a parsed file to set options internally and
;; add task objects to the internal tables.
;;
;;;;;;;;;;;;

(define (sched:set-hours-per-day-of-week string) 
  (let ((hours-per-day-list (parser:split string ", ")))
    (define parsed-list
      (map (lambda (duration-string)
	     (t:string->duration
	      (string-append "0d-" duration-string "-0m")))
	   hours-per-day-list))
    (pp "Finished parsing hours-per-day-of-week option: ")
    (pp parsed-list)
    (hash-table/put! options 'work-per-day-of-week parsed-list)))
  

(define (sched:set-daily-task-duration string)
  (let ((padded-duration (string-append "0d-" string)))
    (hash-table/put! options 'daily-task-duration 
		     (t:string->duration padded-duration))))

(define (sched:set-break-interval string)
  (let ((intervals (parser:readline string "-every-")))
    (define punt-interval-string (string-append "0d-0h-" (car intervals)))
    (define tool-interval-string (string-append "0d-" (cadr intervals) "-0m"))
    (hash-table/put! options 'punt-duration 
		     (t:string->duration punt-interval-string))
    (hash-table/put! options 'tool-duration
		     (t:string->duration tool-interval-string))))

(define (sched:set-options option-list)
  (sched:set-hours-per-day-of-week (cadr option-list))
  (sched:set-daily-task-duration (caddr option-list))
  (sched:set-break-interval (cadddr option-list)))

(define (sched:ingest-parsed-tasks parsed-list)
  (sched:set-options (car parsed-list))
  (sched:make-tasks (cdr parsed-list)))

(define (sched:make-tasks task-list) 
  (for-each 
   (lambda (task) 
     (sched:make-task
      (second task)
      (third task)
      (t:string->instant (fourth task))
      (t:string->duration (fifth task))
      (sixth task)))
   task-list))

(define (sched:make-task id description deadline duration dependencies)
  (define parsed-id (string->symbol (string-append "task-" id)))
  (define parsed-dependencies)
  (if (> (string-length dependencies) 0)
      (set! parsed-dependencies 
	    (map 
	     (lambda (dep) (string->symbol (string-append "task-" dep)))
	     (parser:readline dependencies ", ")))
      (set! parsed-dependencies '()))
  (define new-task
    `((id ,parsed-id)
      (description ,description)
      (deadline ,deadline)
      (duration ,duration)
      (dependencies ,parsed-dependencies)))
  (cond ((> (length parsed-dependencies) 0)
	 (hash-table/put! blocked-tasks parsed-id new-task))
	(else 
	 (hash-table/put! available-tasks parsed-id new-task))))


;;;;;;;;;;;;
;;
;; HELPER FUNCTIONS
;;
;;;;;;;;;;;;

(define (is-table-empty? hash-table)
  (eqv? 0 (length (hash-table/key-list hash-table))))

;; Accepts an instant and returns the duration of hours which should be
;; worked on that instant's day of the week.
(define (get-todays-work-duration instant)
  (list-ref
   (hash-table/get options 'work-per-day-of-week #f)
   (decoded-time/day-of-week (cadr instant))))

;; Checks if two instants are on the same day.
(define (on-same-day? first-instant second-instant)
  (boolean/and (eqv? (decoded-time/day (cadr first-instant))
		    (decoded-time/day (cadr second-instant)))
	       (eqv? (decoded-time/month (cadr first-instant))
		    (decoded-time/month (cadr second-instant)))
	       (eqv? (decoded-time/year (cadr first-instant))
		    (decoded-time/year (cadr second-instant)))))


;; Given some task:
;; 1 - Checks it's in the available-tasks table
;; 2 - Removes it from available-tasks
;; 3 - Adds it to completed-tasks
(define (mark-task-complete task)
  (hash-table/lookup
   available-tasks
   (task-id task)
   (lambda (task)
     (hash-table/remove! available-tasks (task-id task))
     (hash-table/put! completed-tasks (task-id task) task))
   (lambda () (error "Tried to mark task complete but it wasn't available."))))

;; Given some task and a new duration:
;; 1 - Retrieves that task from the available-tasks table
;; 2 - Builds a new task object with the updated duration
;; 3 - Puts the updated task back in the available-tasks table
(define (update-task-duration task duration)
  (hash-table/lookup
   available-tasks
   (task-id task)
   (lambda (task)
     (hash-table/put!
      available-tasks
      (task-id task)
      `((id ,(task-id task))
	(description ,(task-desc task))
	(deadline ,(task-deadline task))
	(duration ,duration)
	(dependencies ,(task-dependencies task)))))
   (lambda () 
     (error "Tried to update task duration but task wasn't available."))))

;; Given a task, generates its next block-id.  The format is:
;; "<task-id>-<block-id>", where <block-id> is an incrementing integer
;; starting at 1.  Checks the last-allocated-block table to determine if this
;; is the first block or if we need to keep incrementing.
(define (incremented-block-id task)
  (hash-table/lookup
   last-allocated-block
   (task-id task)
   (lambda (last-block) 
     (let ((last-block-id 
	    (string->number 
	     (caddr (parser:readline 
		    (symbol->string (block-id last-block)) "-")))))
       (string->symbol
	(string-append 
	 (symbol->string (task-id task))
	 "-" 
	 (number->string (+ last-block-id 1))))))
   (lambda ()
     (string->symbol (string-append (symbol->string (task-id task)) "-1")))))

;; Given a task, finds the dependent-block-ids for its next block.  Two cases:
;; 1 - A work-block has already been allocated, so the next one only depends
;;     on the previous one.
;; 2 - A work-block has not yet been allocated, so this block needs to list the
;;     block-ids of all the dependent tasks' final workblocks.
(define (get-dependent-block-ids task)
  (hash-table/lookup
   last-allocated-block
   (task-id task)
   (lambda (last-block)
     (block-id last-block))
   (lambda ()
     (map 
      (lambda (dependent-task-id)
	(hash-table/lookup
	 last-allocated-block
	 dependent-task-id
	 (lambda (last-block) (block-id last-block))
	 (lambda () 
	   (error "dependent-task-id not found in last-allocated-block table"))))
      (task-dependencies task)))))

;; Given a task, a desired workblock duration, and a start-time, queries
;; the task to build and return a new workblock object with the desired
;; parameters.
(define (make-work-block task duration start-time)
  `((block-id ,(incremented-block-id task))
    (dependent-ids ,(get-dependent-block-ids task))
    (description ,(task-desc task))
    (task-id ,(task-id task))
    (duration ,duration)
    (start-time ,start-time)
    (deadline ,(task-deadline task))))


;;;;;;;;;;;;
;;
;; CORE SCHEDULER ALGORITHM FUNCTIONS
;;
;;;;;;;;;;;;

;; Given one task and the current time, compute:
;;
;; (work-hours-remaining - remaining-duration)
;;
;; and return the value as a duration.
(define (compute-time-remaining task current-time)
  (define (task-time-remaining current-time deadline total-duration)
    (cond
     ((on-same-day? current-time deadline)
      (let ((time-today (t:- deadline current-time)))
	(t:- (t:+ total-duration time-today) 
	     (task-duration task))))
     (else
      (task-time-remaining 
       (get-next-day current-time) 
       deadline
       (t:+ total-duration (get-todays-work-duration current-time))))))
  (task-time-remaining current-time (task-deadline task) '(duration 0 0 0)))
  

;; Iterate through the available-tasks and select the one which is most urgent.
(define (select-task)
  (let ((smallest-duration '(duration 25 0 0))
	(most-urgent-task 
	 (hash-table/get available-tasks 
			 (car (hash-table/key-list available-tasks))
			 #f)))
    (for-each 
     (lambda (task) 
       (let ((time-remaining (compute-time-remaining task current-time)))
	 (cond 
	  ((t:< time-remaining smallest-duration)
	   (set! smallest-duration time-remaining)
	   (set! most-urgent-task task)))))
     (hash-table/datum-list available-tasks))
    (display "Selected a task: ")
    (pp most-urgent-task)
    most-urgent-task))



;; Given a task and desired work-block duration:
;; 1) Create a new work-block with desired parameters
;; 2) Add it to the schedule
;; 3) Decrement the duration of task by the duration of the work-block
;; 3a) If the task is now complete (i.e. duration is 0), then remove it
;;     from the available-tasks table and add it to completed-tasks
(define (allocate-work-block task)
  (let ((block-duration (t:seconds->duration 
			 (min (t:duration->seconds (task-duration task))
			      (t:duration->seconds duration-until-break)
			      (t:duration->seconds daily-time-remaining)))))
    (define remaining-task-time (t:- (task-duration task) block-duration))
    (define new-block (make-work-block task block-duration current-time))
    (hash-table/put!
     last-allocated-block
     (task-id task)
     new-block)
    (display "Working on task '")
    (display (task-desc task))
    (display "', starting at ")
    (t:print current-time)
    (display "' for ")
    (t:print block-duration)
    (display ".")
    (newline)

    (set! schedule (append schedule (list new-block)))
    (set! duration-until-break (t:- duration-until-break block-duration))
    (set! daily-time-remaining (t:- daily-time-remaining block-duration))
    (set! current-time (t:+ current-time block-duration))
    (update-task-duration task remaining-task-time)

    (if (eqv? (t:duration->seconds remaining-task-time) 0)
	(mark-task-complete task))))

;; For a given task with a given dependencies list, check if all of the
;; dependency ids are keys in the completed-tasks table.  Automatically
;; returns true if there are no dependencies (e.g. dependencies is an
;; empty list).
(define (is-task-available? task)
  (define (is-complete? dependencies)
    (if (pair? dependencies)
	(and (hash-table/get completed-tasks (car dependencies) #f)
	     (is-complete? (cdr dependencies)))
	#t))
  (is-complete? (task-dependencies task)))

;; Iterate through all of the tasks in blocked-tasks, check if any of them
;; are available, and move them to the available-tasks table.
(define (refresh-available-tasks)
  (pp "Refreshing our tasks...")
  (hash-table/for-each 
   blocked-tasks
   (lambda (id task) 
     (cond
      ((is-task-available? task)
       (hash-table/put! available-tasks id task)
       (hash-table/remove! blocked-tasks id))))))


;; Thunk.  Checks the status of duration-until-break and daily-time-remaining
;; to determine if current-time needs to be updated before 
(define (add-work-block)
  (display "Adding a new work block, current time is: ")
  (t:print current-time)
  (cond
   ((eqv? (t:duration->seconds daily-time-remaining) 0)
    (display "End of the day, jumping to tomorrow.")
    (set! current-time (get-next-day current-time))
    (set! daily-time-remaining (get-todays-work-duration current-time))
    (set! duration-until-break (get-option 'tool-duration)))
   ((eqv? (t:duration->seconds duration-until-break) 0)
    (display "End of tool-time, jumping one break interval later.")
    (set! current-time (t:+ current-time (get-option 'punt-duration)))
    (set! duration-until-break (get-option 'tool-duration))))
  (allocate-work-block (select-task)))

;;;;;;;;;;;;
;;
;; SCHEDULER MAIN FUNCTION
;; 
;; Generates the actual schedule using the core algorithm functions, assumes
;; that all tasks have already been input into the system, and returns a list
;; of sequential work-blocks.
;;
;;;;;;;;;;;;

(define (sched:get-schedule)
  (cond

   ; If there are no more blocked or available tasks, return the schedule.
   ((and (is-table-empty? available-tasks)
	 (is-table-empty? blocked-tasks))
    schedule)

   ; If there are no available tasks and blocked tasks isn't empty, then
   ; throw an error: tasks had unsolveable dependencies.
   ((and (is-table-empty? available-tasks)
	 (not (is-table-empty? blocked-tasks)))
    (error "Could not build schedule because these tasks had uncompletable dependencies."
	   (pp (hash-table->alist blocked-tasks))))

   ; If there are available tasks, then perform one iteration of
   ; add-work-block and recurse.
   ((not (is-table-empty? available-tasks))
    (add-work-block)
    (refresh-available-tasks)
    (sched:get-schedule))
   
   ; If none of these cases are true, throw an error because that isn't
   ; expected behavior.
   (else
    (error "Unexpected behavior while building sched:get-schedule"
	   (list available-tasks blocked-tasks)))))
