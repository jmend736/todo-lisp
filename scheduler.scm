;; TITLE: scheduler.scm
;; AUTHOR: John O'Sullivan <johno@mit.edu>

;; This file contains the code to create tasks, schedule them into a series of
;; work blocks, and then return a sequential list of all scheduled work blocks.

(define current-time
  ('instant (universal-time->local-decoded-time (get-universal-time))))

(define options (make-eq-hash-table))
(hash-table/put! options task-hours-per-day 8)
(hash-table/put! options monday-hours 8)
(hash-table/put! options tuesday-hours 8)
(hash-table/put! options wednesday-hours 8)
(hash-table/put! options thursday-hours 8)
(hash-table/put! options friday-hours 8)
(hash-table/put! options saturday-hours 8)
(hash-table/put! options sunday-hours 8)
(hash-table/put! options tool-duration ('duration 0 3 0))
(hash-table/put! options punt-duration ('duration 0 0 15))

(define (set-hours-per-day-of-week string) 

  )

(define (set-task-hours-per-day string)
  
  )

(define (set-work-durations string)

  )

(define completed-tasks (make-eq-hash-table)
(define available-tasks (make-eq-hash-table)
(define blocked-tasks (make-eq-hash-table))
(define all-tasks (make-eq-hash-table))

(define (make-task id description deadline duration dependencies)
  (define new-task
    ('task
     ('id id)
     ('description description)
     ('deadline deadline)
     ('duration duration)
     ('dependencies dependencies)))
  (hash-table/put! all-tasks id new-task)
  (cond ((pair? dependencies) (hash-table/put! blocked-tasks id new-task))
	(else (set available-tasks (hash-table/put! available-tasks id new-task)))))

(define (select-task available-tasks completed-tasks)
  (let ((most-urgent 
	 (hash-table/get available-tasks 
			 (car (hash-table/key-list available-tasks))))
	(time-remaining ))
  )

(define (compute-time-remaining task current-time)

  )

(define (get-work-block task duration)
  
  )




(define (refresh-available-tasks blocked-tasks completed-tasks available-tasks)
  (hash-table/for-each 
   blocked-tasks
   (lambda (id task) 
     (cond
      ((is-task-available? task completed-tasks)
       (hash-table/put! available-tasks id task)
       (hash-table/remove! blocked-tasks id)))))
  (list available-tasks blocked-tasks completed-tasks))

(define (build-schedule all-tasks available-tasks blocked-tasks)
  (let ((schedule-list '()))
    ())
  )

(define (is-task-available? task completed-tasks)
  (define (is-complete? dependencies)
    (and (hash-table/get completed-tasks (car dependencies) #f)
	 (is-complete? (cdr dependencies))))
  (is-complete? task))


