;;emulates python's split function
;;"1,23,3" -> ("1" "23" "3")
(define (parser:split line delimiter)
  (let lp ((out '())
	   (rest line))
    (let ((pos (string-search-forward delimiter rest)))
      (cond
       ((eq? 0 (string-length delimiter)) (list rest))
       ((not pos) (reverse (cons rest  out)))
       (else (lp (cons (string-head rest pos) out)
		 (string-tail rest (+ (string-length delimiter) pos))))))))



(define (parser:readline line delimiter)
  (map string-trim (parser:split line delimiter)))

(define (parser:valid:id? candidate)
  (integer? (string->number candidate)))

(define (parser:valid:description? candidate)
  (string? candidate))

;;given a "time expression", checks to see if 'candidate' is a series of
;;ints followed by 'interval'
(define (parser:valid:time-arg? candidate interval)
  (if (not (and (string? interval)
		(> (string-length interval) 0)))
      (error "parser:valid:time-arg? -> Interval must be a string and have a length > 0")
      (and (string? candidate)
	   (>= (string-length candidate) 2)
	   (string-search-backward interval candidate)
	   (integer?
	    (string->number (string-head candidate
					 (- (string-length
					     candidate)
					    (string-length
					     interval))))))))

(define (parser:valid:duration? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (and (eq? 3 (length args))
	      (parser:valid:time-arg? (car args) "d")
	      (parser:valid:time-arg? (cadr args) "h")
	      (parser:valid:time-arg? (caddr args) "m")))))


;;sees if n -> [lower, upper]
(define (parser:within-range? n lower upper)
  (if (not (every integer? (list n lower upper)))
      (error "n, lower, and upper must all be integers")
      (and (>= n lower) (<= n upper))))



(define (parser:count-digits n)
  (let lp ((digits 1)
	   (rest n))
    (if (< rest 10)
	digits
	(lp (+ 1 digits) (integer-floor rest 10)))))

(define (parser:valid:deadline? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (and (eq? 5 (length args))
	      (let* ((nums (map string->number args))
		     (year (car nums))
		     (month (cadr nums))
		     (day (caddr nums))
		     (hours (cadddr nums))
		     (mins (last nums)))
					;YYYY-MM-DD-HH-MM
		(and (every integer? nums)

		     (every (lambda (x) (eq? 2 (string-length x)))
			    (cdr args))

					;year can be anything
		     
		     (parser:within-range? month 1 12)

		     (parser:within-range? day 1 31)

		     (parser:within-range? hours 0 23)

		     (parser:within-range? mins 0 59)))))))


(define (parser:valid:dependencies? candidate)
  (and (string? candidate)
       (or
	(eq? 0 (string-length candidate))
	(let ((args (parser:readline candidate ",")))
	  (every integer? (map string->number args))))))



(define (parser:valid:hours-per-day? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate ",")))
	 (and (eq? 7 (length args))
	      (every
	       (lambda (x)
		 (and (parser:valid:time-arg? x "h")
		      (parser:within-range?
		       (string->number (string-head x (- (string-length
							  x) 1)))
		       0 24)))
	       args)))))



(define (parser:valid:time-per-task? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "h")
	      (parser:valid:time-arg? (cadr args) "m")))))

(define (parser:valid:break-interval? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-every-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "m")
	      (parser:valid:time-arg? (cadr args) "h")))))


(define (parser:task:id t)
  (cadr t))

(define (parser:task:description t)
  (caddr t))

(define (parser:task:deadline t)
  (cadddr t))

(define (parser:task:duration t)
  (general-car-cdr t #b110000))

(define (parser:task:dependencies t)
  (general-car-cdr t #b1100000))

(define parser:error:length 'error:length)
(define parser:error:id 'error:id)
(define parser:error:duration 'error:duration)
(define parser:error:deadline 'error:deadline)
(define parser:error:description 'error:description)
(define parser:error:dependencies 'error:dependencies)

(define (parser:option:hours-per-day o)
  (cadr o))

(define (parser:option:time-per-task o)
  (caddr o))

(define (parser:option:break-interval o)
  (cadddr o))

(define parser:error:hours-per-day 'error:hours-per-day)
(define parser:error:time-per-task 'error:time-per-task)
(define parser:error:break-interval 'error:break-interval)




;; if candidate is valid, returns a task object, otherwise returns error an error
;; symbol that tells you how it was poorly formed
(define (parser:valid:task? candidate field-delimiter)
  (let ((args (cons 'task (parser:readline candidate field-delimiter))))
    (cond ((not (eq? 6 (length args))) parser:error:length)
	  ((not (parser:valid:id? (parser:task:id args))) parser:error:id)
	  ((not (parser:valid:description? (parser:task:description
					    args))) parser:error:description)
	  ((not (parser:valid:duration? (parser:task:duration
					 args))) parser:error:duration)
	  ((not (parser:valid:deadline? (parser:task:deadline
					 args))) parser:error:deadline)
	  ((not (parser:valid:dependencies? (parser:task:dependencies
					     args)))
	   parser:error:dependencies)
	  (else args))))

;; if candidate is valid, returns an options object, otherwise returns error an error
;; symbol that tells you how it was poorly formed
(define (parser:valid:options? candidate field-delimiter)
  (let ((args (cons 'options (parser:readline candidate
					      field-delimiter))))
    
    (cond ((not (eq? 4 (length args))) parser:error:length)
	  ((not (parser:valid:hours-per-day?
		 (parser:option:hours-per-day args)))
	   parser:error:hours-per-day)
	  
	  ((not (parser:valid:time-per-task?
		 (parser:option:time-per-task args)))
	   parser:error:time-per-task)
	  
	  ((not (parser:valid:break-interval?
		 (parser:option:break-interval args)))
	   parser:error:break-interval)
	  
	  (else args))))













