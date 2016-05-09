(define (get-date-string block)
  (let ((decoded-start-time (cadr (block-start-time block))))
    (string-append 
     "\n"
     "------"
     (number->string (decoded-time/year decoded-start-time))
     "/"
     (number->string (decoded-time/month decoded-start-time))
     "/"
     (number->string (decoded-time/day decoded-start-time))
     "------"
     "\n")))

(define (get-block-listing block)
  (string-append
   (get-duration-string block)
   " :: "
   (symbol->string (block-id block))
   " / "
   (cadr (assv 'description block))
   "\n"))

(define (print-time instant)
  (let ((hours (number->string (decoded-time/hour (cadr instant))))
	(minutes (number->string (decoded-time/minute (cadr instant)))))
    (if (< (string-length hours) 2)
	(set! hours (string-append "0" hours)))
    (if (< (string-length minutes) 2)
	(set! minutes (string-append "0" minutes)))
    (string-append hours ":" minutes)))

(define (get-duration-string block)
  (let ((block-start (block-start-time block))
	(block-duration (cadr (assv 'duration block))))
    (define block-end (t:+ block-start block-duration))
    (string-append (print-time block-start) " - " (print-time block-end))))


(define (print-schedule schedule output-name)
  (let ((outfile (open-output-file output-name)))
    (set-current-output-port! outfile)
    (define last-block 'start)
    (for-each
     (lambda (work-block)
       (cond 
	((eq? last-block 'start) (write-string (get-date-string work-block)))
	((not (on-same-day? (block-start-time last-block) 
			    (block-start-time work-block)))
	 (write-string (get-date-string work-block))))
       (write-string (get-block-listing work-block))
       (set! last-block work-block))
     schedule)
    (close-port outfile)))