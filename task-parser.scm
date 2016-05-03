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

#|Test Cases:
;;(parser:split "Hello, my, geoffrey" ",")
;;Value 20: ("Hello" " my" " geoffrey")

;;(parser:split "Hello, my, geoffrey" "")
;;Value 21: ("Hello, my, geoffrey")

;;(parser:split "Hello my geoffrey" ",")
;;Value 22: ("Hello my geoffrey")
|#

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
#|Test Cases:
(parser:valid:time-arg? "33d" 'd)
;error: parser:valid:time-arg? -> Interval must be a string and have a length > 0

(parser:valid:time-arg? "33d" "")
;error: parser:valid:time-arg? -> Interval must be a string and have a length > 0

(parser:valid:time-arg? "33d" "d")
;Value #t

(parser:valid:time-arg? "33" "d")
;Value: #f

(parser:valid:time-arg? "NaN" "d")
;Value: #f

(parser:valid:time-arg? "NaNd" "d")
;Value: #f

(parser:valid:time-arg? "NaN3d" "d")
;Value: #f

(parser:valid:time-arg? "43mm" "mm")
;Value #t
|#

(define (parser:valid:duration? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (pp args)
	 (and (eq? 3 (length args))
	      (parser:valid:time-arg? (car args) "d")
	      (parser:valid:time-arg? (cadr args) "h")
	      (parser:valid:time-arg? (caddr args) "m")))))

#|Test Cases:
;;(parser:valid:duration? "XXd-XXh-XXm")
;;Value: #f

;;(parser:valid:duration? "3d-00h-00m")
;;Value: #t

;;(parser:valid:duration? "0003d-00h-00m")
;;Value: #t

;;(parser:valid:duration? "0d-72h-00m")
;;Value: #t

;;(parser:valid:duration? "00d-00h-4320m")
;;Value: #t

;;(parser:valid:duration? "11d-22h-63m")
;;Value: #t

;;(parser:valid:duration? "22h-11d-63m")
;;Value: #f

;;(parser:valid:duration? "11d-63m")
;;Value: #f
|#

;;sees if n -> [lower, upper]
(define (parser:within-range? n lower upper)
  (if (not (every integer? (list n lower upper)))
      (error "n, lower, and upper must all be integers")
      (and (>= n lower) (<= n upper))))

#|Test Cases:
;;(parser:within-range? 1 1 12)
;;Value: #t

;;(parser:within-range? 12 1 12)
;;Value: #t

;;(parser:within-range? 3 1 12)
;;Value: #t

;;(parser:within-range? 0 1 12)
;;Value: #f

;;(parser:within-range? 13 1 12)
;;Value: #f
|#


(define (parser:count-digits n)
  (let lp ((digits 1)
	   (rest n))
    (if (< rest 10)
	digits
	(lp (+ 1 digits) (integer-floor rest 10)))))

(parser:count-digits 10)

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

#|Test Cases:
;;(parser:valid:deadline? "1958-09-09-11-58")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09")
;;Value: #f

;;(parser:valid:deadline? "1158")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09-")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09-00-58")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09-23-58")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09-00-00")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09-24-00")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09-11-60")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09-a1-24")
;;Value: #f

;;(parser:valid:deadline? "9045-09-09-11-58")
;;Value: #t

;;(parser:valid:deadline? "195-09-09-11-58")
;;Value: #t

;;(parser:valid:deadline? "a3ab-09-09-11-58")
;;Value: #f

;;(parser:valid:deadline? "aabb-09-09-11-58")
;;Value: #f

;;(parser:valid:deadline? "1958-01-09-11-58")
;;Value: #t

;;(parser:valid:deadline? "1958-12-09-11-58")
;;Value: #t

;;(parser:valid:deadline? "1958-13-09-11-58")
;;Value: #f

;;(parser:valid:deadline? "1958-1-09-11-58")
;;Value: #f

;;(parser:valid:deadline? "1958-01-aa-11-58")
;;Value: #f

;;(parser:valid:deadline? "1958-01-1-11-58")
;;Value: #f

;;(parser:valid:deadline? "1958-01-01-11-58")
;;Value: #t

;;(parser:valid:deadline? "1958-01-31-11-58")
;;Value: #t

;;(parser:valid:deadline? "1958-01-32-11-58")
;;Value: #f
|#

(define (parser:valid:dependencies? candidate)
  (and (string? candidate)
       (or
	(eq? 0 (string-length candidate))
	(let ((args (parser:readline candidate ",")))
	  (every integer? (map string->number args))))))

#|Test Cases:
;;(parser:valid:dependencies? "")
;;Value: #f

;;(parser:valid:dependencies? ",")
;;Value: #f

;;(parser:valid:dependencies? "22, 44")
;;Value: #t

;;(parser:valid:dependencies? "22, 44,")
;;Value: #f

;;(parser:valid:dependencies? "22, 44, 100.")
;;Value: #t

;;(parser:valid:dependencies? "22, 44, 100.3")
;;Value: #f
|#

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

#|Test Cases:
;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h ,0h")
;;Value: #t

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h , 55h")
;;Value: #f

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3d, 2h, 0h , 0h")
;;Value: #f
|#

(define (parser:valid:time-per-task? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "h")
	      (parser:valid:time-arg? (cadr args) "m")))))

#|Test Cases:
;;(parser:valid:time-per-task? "03h-15m")
;;Value: #t

;;(parser:valid:time-per-task? "03h-1mm")
;;Value: #f
|#

(define (parser:valid:break-interval? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-every-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "m")
	      (parser:valid:time-arg? (cadr args) "h")))))

#|Test Cases:
;;(parser:valid:break-interval? "XXm-every-XXh")
;;Value: #f

;;(parser:valid:break-interval? "45m-every-09h")
;;Value: #f
|#

(define (parser:task:id t)
  (cadr t))

(define (parser:task:description t)
  (caddr t))

(define (parser:task:duration t)
  (cadddr t))

(define (parser:task:deadline t)
  (general-car-cadr t #b110000))

(define (parser:task:dependencies t)
  (general-car-cadr t #b1100000))

(define parser:error:length 'error:length)
(define parser:error:id 'error:id)
(define parser:error:duration 'error:duration)
(define parser:error:deadline 'error:deadline)
(define parser:error:description 'error:description)
(define parser:error:dependencies 'error:dependencies)

 
(define (parser:valid:task? candidate field-delimiter)
  (let ((args (parser:readline candidate field-delimiter)))
    (cond ((not (eq? 5 (length args))) parser:error:length)
	  ((not (parser:valid:id? (parser:task:id candidate))) parser:error:id)
	  ((not (parser:valid:description? (parser:task:description
					    candidate))) parser:error:description)
	  ((not (parser:valid:duration? (parser:task:duration
					 candidate))) parser:error:duration)
	  ((not (parser:valid:deadline? (parser:task:deadline
					 candidate))) parser:error:deadline)
	  ((not (parser:valid:dependencies? (parser:task:dependencies
					     candidate)))
	   parser:error:dependencies)
	  (else #t))))

;;(parser:valid:task? "1 #! task 1 depends on task 2  #!
;1958-09-09-11-58 #! 11d-22h-63m #! 2" "#!")








