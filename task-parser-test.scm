#|parser:split Test Cases:
;;(parser:split "Hello, my, geoffrey" ",")
;;Value 20: ("Hello" " my" " geoffrey")

;;(parser:split "Hello, my, geoffrey" "")
;;Value 21: ("Hello, my, geoffrey")

;;(parser:split "Hello my geoffrey" ",")
;;Value 22: ("Hello my geoffrey")
|#

#|parser:valid:time-arg? Test Cases:
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


#|parser:valid:duration Test Cases:
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


#|parser:within-range? Test Cases:
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

#|parser:valid:deadline? Test Cases:
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

#|parser:valid:dependencies? Test Cases:
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

#|parser:valid:hours-per-day? Test Cases:
;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h ,0h")
;;Value: #t

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3h, 2h, 0h , 55h")
;;Value: #f

;;(parser:valid:hours-per-day? "8h , 8h, 5h ,3d, 2h, 0h , 0h")
;;Value: #f
|#

#|parser:valid:time-per-task? Test Cases:
;;(parser:valid:time-per-task? "03h-15m")
;;Value: #t

;;(parser:valid:time-per-task? "03h-1mm")
;;Value: #f
|#

#|parser:valid:task? Test Cases:
(parser:valid:task? "1 #! task 1 depends on task 2 #! 1958-09-09-11-58#! 11d-22h-63m #! 2" "#!")
;;(task "1" "task 1 depends on task 2" "1958-09-09-11-58" "11d-22h-63m" "2")

(parser:valid:task? "2 #! task 2 depends on nothing #! 1958-09-09-01-40 #! 00d-00h-30m #!" "#!")
;;(task "2" "task 2 depends on nothing" "1958-09-09-01-40" "00d-00h-30m" "")

(parser:valid:task? "2 #! task 2 depends on nothing #!
1958-09-09-01-40 #! 00d-00h-30m" "#!")
;;'error:length

(parser:valid:task? "2 #! task 2 depends on nothing 1958-09-09-01-40
#! 00d-00h-30m #!" "#!")
;;'error:length

(parser:valid:task? "2 #! task 2 depends on nothing #!
1958-09-09-01-40 #! 00d-00h-30m #!" "!")
;;'error:id

(parser:valid:task? "two #! task 2 depends on nothing #!
1958-09-09-01-40 #! 00d-00h-30m #!" "#!")
;;'error:id

(parser:valid:task? "2 #!#! 1958-09-09-01-40 #! 00d-00h-30m #!" "#!")
;;(task "2" "" "1958-09-09-01-40" "00d-00h-30m" "")
;;descr can be empty

(parser:valid:task? "2 #! task 2 depends on nothing #! 1989-09-01-40
#! 00d-00h-30m #!" "#!")
;;error:deadline

(parser:valid:task? "2 #! task 2 depends on nothing #!
1958-09-09-01-40 #! 00-00h-30m #!" "#!")
;;error:duration

(parser:valid:task? "2 #! task 2 depends on nothing #!
1958-09-09-01-40 #! 00d-00h-30m #! one" "#!")
;;error:dependencies 
|#

#|parser:valid:options? Test Cases:

(parser:valid:options? "8h, 8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #!
45m-every-09h" "#!")

(parser:valid:options? "8, 8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #!
45m-every-09h" "#!")
;;error:hours-per-day

(parser:valid:options? "8h 8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #!
45m-every-09h" "#!")
;;error:hours-per-day

(parser:valid:options? "8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #!
45m-every-09h" "#!")
;;error:hours-per-day

(parser:valid:options? "8h, 8h, 5h, 3h, 2h, 0h, 0h #! 03-15m #!
45m-every-09h" "#!")
;;error:time-per-task

(parser:valid:options? "8h, 8h, 5h, 3h, 2h, 0h, 0h #! 03h15m #!
45m-every-09h" "#!")
;;error:time-per-task

(parser:valid:options? "8h, 8h, 5h, 3h, 2h, 0h, 0h #! 03h-15m #!
45m-every09h" "#!")
;;error:break-interval
|#

