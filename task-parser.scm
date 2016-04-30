(define (parser:split line delimiter)
  (let lp ((out '())
	   (rest line))
    (let ((pos (string-search-forward delimiter rest)))
      (cond
       ((eq? 0 (string-length delimiter)) rest)
       ((not pos) (reverse (cons rest  out)))
       (else (lp (cons (string-head rest pos) out)
		 (string-tail rest (+ (string-length delimiter) pos))))))))

;;(parser:split "Hello, my, geoffrey" ",")
;;Value 20: (" geoffrey" " my" "Hello")

;;(parser:split "Hello, my, geoffrey" "")
;;Value 21: "Hello, my, geoffrey"
 
;;(parser:split "Hello my geoffrey" ",")
;;Value 22: ("Hello my geoffrey")


(define (parser:readline line delimiter)
  (map string-trim (parser:split line delimiter)))

(define (parser:valid:id? candidate)
  (integer? (string->number candidate)))

(define (parser:valid:description? candidate)
  (string? candidate))


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

;;(parser:valid:time-arg? "33d" 'd)
;;error: parser:valid:time-arg? -> Interval must be a string and have a length > 0

;;(parser:valid:time-arg? "33d" "")
;;error: parser:valid:time-arg? -> Interval must be a string and have a length > 0

;;(parser:valid:time-arg? "33d" "d")
;;Value #t

;;(parser:valid:time-arg? "33" "d")
;;Value: #f

;;(parser:valid:time-arg? "NaN" "d")
;;Value: #f

;;(parser:valid:time-arg? "NaNd" "d")
;;Value: #f

;;(parser:valid:time-arg? "NaN3d" "d")
;;Value: #f

;;(parser:valid:time-arg? "43mm" "mm")
;;Value #t

(define (parser:valid:duration? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (pp args)
	 (and (eq? 3 (length args))
	      (parser:valid:time-arg? (car args) "d")
	      (parser:valid:time-arg? (cadr args) "h")
	      (parser:valid:time-arg? (caddr args) "m")))))

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

;;inclusive?
(define (parser:within-range? n lower upper)
  (if (not (every integer? (list n lower upper)))
      (error "n, lower, and upper must all be integers")
      (and (>= n lower) (<= n upper))))

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

(define (parser:valid:deadline? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate ";")))
	 (and (eq? 2 (length args))
					;right half 

	      (eq? 4 (string-length (cadr args)))
	      (integer? (string->number (cadr args)))
					;HH
	      (parser:within-range? (string->number
				     (string-head (cadr args) 2)) 00
				     23)
					;MM
	      (parser:within-range? (string->number
				     (string-tail (cadr args) 2)) 00
				     59)



					;left half
	      (let ((date (parser:readline (car args) "-")))
		(and (eq? 3 (length date))
		     (every integer? (map string->number date))
					;YYYY
		     (eq? 4 (string-length (car date)))

					;MM
		     (eq? 2 (string-length (cadr date)))
		     (parser:within-range? (string->number
					    (cadr
					     date)) 1
					     12)

					;DD
		     (eq? 2 (string-length (caddr date)))
		     (parser:within-range? (string->number (caddr
							    date))
					   1 31)))))))

;;(parser:valid:deadline? "1958-09-09;1158")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09")
;;Value: #f

;;(parser:valid:deadline? "1158")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09;")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09;0058")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09;2358")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09;0000")
;;Value: #t

;;(parser:valid:deadline? "1958-09-09;2400")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09;1160")
;;Value: #f

;;(parser:valid:deadline? "1958-09-09;a124")
;;Value: #f

;;(parser:valid:deadline? "9045-09-09;1158")
;;Value: #t

;;(parser:valid:deadline? "195-09-09;1158")
;;Value: #f

;;(parser:valid:deadline? "a3ab-09-09;1158")
;;Value: #f

;;(parser:valid:deadline? "aabb-09-09;1158")
;;Value: #f

;;(parser:valid:deadline? "1958-01-09;1158")
;;Value: #t

;;(parser:valid:deadline? "1958-12-09;1158")
;;Value: #t

;;(parser:valid:deadline? "1958-13-09;1158")
;;Value: #f

;;(parser:valid:deadline? "1958-1-09;1158")
;;Value: #f

;;(parser:valid:deadline? "1958-01-aa;1158")
;;Value: #f

;;(parser:valid:deadline? "1958-01-1;1158")
;;Value: #f

;;(parser:valid:deadline? "1958-01-01;1158")
;;Value: #t

;;(parser:valid:deadline? "1958-01-31;1158")
;;Value: #t

;;(parser:valid:deadline? "1958-01-32;1158")
;;Value: #f

(define (parser:valid:dependencies? candidate)
  (and (string? candidate)
       (or
	(eq? 0 (string-length candidate))
	(let ((args (parser:readline candidate ",")))
	  (every integer? (map string->number args))))))


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

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h ,0h")
;;Value: #t

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h , 55h")
;;Value: #f

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3d, 2h, 0h , 0h")
;;Value: #f

(define (parser:valid:time-per-task? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "h")
	      (parser:valid:time-arg? (cadr args) "m")))))


;;(parser:valid:time-per-task? "03h-15m")
;;Value: #t

;;(parser:valid:time-per-task? "03h-1mm")
;;Value: #f

(define (parser:valid:break-interval? candidate)
  (and (string? candidate)
       (let ((args (parser:readline candidate "-every-")))
	 (and (eq? 2 (length args))
	      (parser:valid:time-arg? (car args) "m")
	      (parser:valid:time-arg? (cadr args) "h")))))

;;(parser:valid:break-interval? "XXm-every-XXh")
;;Value: #f

;;(parser:valid:break-interval? "45m-every-09h")
;;Value: #f


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


(define (parser:valid:task? candidate task-delimiter)
  (let ((args (parser:readline args task-delimiter)))
    (and (eq? 6 (length args))
	 (parser:valid:id? (parser:task:id candidate))
	 (parser:valid:description? (parser:task:description
				     candidate))
	 (parser:valid:duration? (parser:task:duration candidate))
	 (parser:valid:deadline? (parser:task:deadline candidate))
	 (parser:valid:dependencies? (parser:task:dependencies
				      candidate)))))



