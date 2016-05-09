;; TITLE: time-arith.scm
;; AUTHOR: John O'Sullivan <johno@mit.edu>

;; This implements a set of generic operators for adding and subtracting durations
;; of time from instants of time (e.g. 7pm + 1h = 8pm).  Durations are internally
;; stored in total number of seconds, instants are stored as Scheme decoded time
;; objects.

;; PREDICATES

(define (tagged-list? exp sym)
  (eq? (car exp) sym))

(define (t:duration? exp) (tagged-list? exp 'duration))
(register-predicate! t:duration? 'duration)
(define (t:instant? exp) (tagged-list? exp 'instant))
(register-predicate! t:instant? 'instant)

(display "(t:duration? '(duration 0 1 0)): ")
(pp (t:duration? `(duration 0 1 0)))

;; CONSTANTS

(define t:minute
  60)

(define t:hour
  (* t:minute 60))

(define t:day
  (* t:hour 24))

(define t:week
  (* t:day 7))

;; HELPERS

(define (t:get-int string)
  (string->number (string-head string (- (string-length string) 1))))

(define (t:select-instant left right)
  (cond
   ((t:instant? left) left)
   ((t:instant? right) right)
   (else (error "Called select-instant and neither args were instants."))))

(define (t:select-duration left right)
  (cond
   ((t:duration? left) left)
   ((t:duration? right) right)
   (else (error "Called select-duration and neither args were durations."))))

;; CONVERTERS

(define (t:duration->seconds duration)
  (+ (* t:day (cadr duration))
     (* t:hour (caddr duration))
     (* t:minute (cadddr duration))))

(define (t:seconds->duration seconds)
  (define days (quotient seconds t:day))
  (set seconds (remainder seconds t:day))
  (define hours (quotient seconds t:hour))
  (set seconds (remainder seconds t:hour))
  (define minutes (quotient seconds t:minute))
  `(duration days hours minutes))

(define (t:instant->seconds instant)
  (display "instant in t:instant->seconds: ")
  (pp instant)
  (decoded-time->universal-time (cadr instant)))

(define (t:seconds->instant seconds)
  `(instant ,(universal-time->local-decoded-time seconds)))

(define (t:string->duration duration-string)
  (let ((split-string (parser:readline duration-string "-")))
    (define duration-seconds
      (+ (* t:day (t:get-int (car split-string)))
	 (* t:hour (t:get-int (cadr split-string)))
	 (* t:minute (t:get-int (caddr split-string)))))
    (t:seconds->duration duration-seconds)))

(define (t:string->instant instant-string)
  (let ((split-instant (parser:readline instant-string "-")))
    `(instant
      ,(make-decoded-time
       0
       (t:get-int (fifth split-instant))
       (t:get-int (fourth split-instant))
       (t:get-int (third split-instant))
       (t:get-int (second split-instant))
       (t:get-int (first split-instant))))))


;; GENERIC ARITHMETIC PROCEDURES

;; The sum of two durations is a longer duration.  The sum of a duration and an
;; instant is a new instant which is that duration further in the future.  The
;; sum of two instants is not supported and throws an error message.

(define t:+ (simple-generic-procedure 't:+ 2))

(define (instant-plus-instant)
  (error "Attempted to sum two instants: " 
		    (error-irritant/noise left)
		    (error-irritant/noise ", ")
		    (error-irritant/noise right)
		    (error-irritant/noise ".")))

(define-generic-procedure-handler
  t:+
  (all-args 2 t:instant?)
  instant-plus-instant)

(define (duration-plus-duration left right)
  (t:seconds->duration (+ (t:duration->seconds left) 
			  (t:duration->seconds right))))

(define-generic-procedure-handler
  t:+
  (all-args 2 t:duration?)
  duration-plus-duration)

(define (duration-plus-instant left right)
  (let ((duration (t:select-duration left right))
	(instant (t:select-instant left right)))
    (t:seconds->instant (+ (t:instant->seconds instant)
			   (t:duration->seconds duration)))))

(define-generic-procedure-handler
  t:+
  (any-arg 2 t:duration? t:instant?)
  duration-plus-instant)


;; The difference between two durations is another duration.  Negative durations
;; are not supported.  The difference between a duration and an instant returns
;; an instant which is that duration before the original.  The difference between
;; two instants is the duration of time between the earlier and later one.

(define t:- (simple-generic-procedure 't:- 2))

(define (instant-minus-instant left right)
    (t:seconds->duration 
     (abs (- (t:instant->seconds left) 
	     (t:instant->seconds right)))))

(define-generic-procedure-handler
  t:-
  (all-args 2 t:instant?)
  instant-minus-instant)

(define (duration-minus-duration left right)
    (t:seconds->duration 
     (abs (- (t:duration->seconds left)
	     (t:duration->seconds right)))))

(define-generic-procedure-handler
  t:-
  (all-args 2 t:duration?)
  duration-minus-duration)

(define (instant-minus-duration left right)
  (let ((instant (t:select-instant left right))
	(duration (t:select-duration left right)))
    (t:seconds->instant (- (t:instant->seconds instant)
			   (t:duration->seconds duration)))))

(define-generic-procedure-handler
  t:-
  (any-arg 2 t:duration? t:instant?)
  instant-minus-duration)



;; An instant is less than another instant if it occurs beforehand (i.e. has
;; a smaller value when represented in universal time), and a duration is less
;; than another duration if it is shorter.  An instant cannot be less than a
;; duration, or vice versa, so those cases are not handled.

(define t:< (simple-generic-procedure 't:< 2))

(define (instant-lt-instant left right)
  (< (t:instant->seconds left)
     (t:instant->seconds right)))

(define-generic-procedure-handler 
  t:<
  (all-args 2 t:instant?)
  instant-lt-instant)

(define (duration-lt-duration left right)
  (< (t:duration->seconds left)
     (t:duration->seconds right)))

(define-generic-procedure-handler
  t:<
  (all-args 2 t:duration?)
  duration-lt-duration)

;; Instant A is greater than Instant B if Instant A is further in the future
;; (i.e. Instant A has a larger universal time representation).  Duration A
;; is greater than Duraton B if it represents a greater number of seconds.
;; An instant cannot be greater than a duration, or vice versa, so those
;; cases are not handled.

(define t:> (simple-generic-procedure 't:> 2))

(define (instant-gt-instant left right)
  (> (t:instant->seconds left)
     (t:instant->seconds right)))

(define-generic-procedure-handler
  t:>
  (all-args 2 t:instant?)
  instant-gt-instant)

(define (duration-gt-duration left right)
  (> (t:duration->seconds left)
     (t:duration->seconds right)))

(define-generic-procedure-handler
  t:>
  (all-args 2 t:duration?)
  duration-gt-duration)



