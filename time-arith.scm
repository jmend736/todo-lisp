;; TITLE: time-arith.scm
;; AUTHOR: John O'Sullivan <johno@mit.edu>

;; This implements a set of generic operators for adding and subtracting durations
;; of time from instants of time (e.g. 7pm + 1h = 8pm).  Durations are internally
;; stored in total number of seconds, instants are stored as Scheme decoded time
;; objects.

(define (duration? exp) (tagged-list? exp 'duration))

(define (instant? exp) (tagged-list? exp 'instant))

(define minute
  60)

(define hour
  (* minute 60))

(define day
  (* hour 24))

(define week
  (* day 7))

(define (duration->seconds duration)
  (+ (* day (cadr duration))
     (* hour (caddr duration))
     (* minute (cadddr duration))))

(define (seconds->duration seconds)
  (define days (quotient seconds day))
  (set seconds (remainder seconds day))
  (define hours (quotient seconds hour))
  (set seconds (remainder seconds hour))
  (define minutes (quote seconds minute))
  (list 'duration days hours minutes))

(define (make-duration durationString)
  ())

(define (select-instant left right)
  (cond
   ((instant? left) left)
   ((instant? right) right)
   (else (error "Called select-instant and neither args were instants."))))

(define (select-duration left right)
  (cond
   ((duration? left) left)
   ((duration? right) right)
   (else (error "Called select-duration and neither args were durations."))))

;; The sum of two durations is a longer duration.  The sum of a duration and an
;; instant is a new instant which is that duration further in the future.  The
;; sum of two instants is not supported and throws an error message.

(define t+
  (make-generic-operator 
   2 't+ (lambda (left right) 
	   (cond 
	    ((and (duration? left) (duration? right))
	     (duration-plus-duration left right))
	    ((and (instant? left) (instant? right))
	     (instant-plus-instant))
	    ((or (and (duration? left) (instant? right))
		 (and (instant? left) (duration? right)))
	     (duration-plus-instant duration instant))))))

(define (duration-plus-duration left right)
  (seconds->duration (+ (duration->seconds left) (duration->seconds right))))

(define (duration-plus-instant duration instant)
  (let ((duration (select-duration left right))
		   (instant (select-instant left right)))
    (define universal-instant
      (decoded-time->universal-time (cadr instant)))
    (define new-universal
      (+ universal-instant (duration->seconds duration)))
    (define new-instant
      (universal-time->local-decoded-time new-universal))
    (list 'duration new-instant)))

(define (instant-plus-instant)
  (error "Attempted to sum two instants: " 
		    (error-irritant/noise left)
		    (error-irritant/noise ", ")
		    (error-irritant/noise right)
		    (error-irritant/noise ".")))


;; The difference between two durations is another duration.  Negative durations
;; are not supported.  The difference between a duration and an instant returns
;; an instant which is that duration before the original.  The difference between
;; two instants is the duration of time between the earlier and later one.
	  
(define t-
  (make-generic-operator 
   2 't- (lambda (left right) 
	   (cond 
	    ((and (duration? left) (duration? right))
	     (duration-minus-duration left right))
	    ((and (instant? left) (instant? right))
	     (instant-minus-instant left right))
	    ((or
	      (and (duration? left) (instant? right))
	      (and (instant? left) (duration? right)))
	     (let ((duration (select-duration left right))
		   (instant (select-instant left right))
		   (instant-minus-duration instant duration))))))))

(define (duration-minus-duration left right)
  (let ((left-seconds (duration->seconds left))
	(right-seconds (duration->seconds right)))
    (define larger (max left-seconds right-seconds))
    (define smaller (min left-seconds right-seconds))
    (seconds->duration (- larger smaller))))

(define (instant-minus-duration instant duration)
  (let ((instant-seconds (decoded-time->universal-time (cadr instant)))
	(duration-seconds (duration->seconds duration)))
    (list 'instant 
	  (universal-time->local-decoded-time
	   (- instant-seconds duration-seconds)))))

(define (instant-minus-instant left right)
  (let ((left-seconds (decoded-time->universal-time left))
	(right-seconds (decoded-time->universal-time right)))
    (seconds->duration 
     (abs (- left-seconds right-seconds)))))












