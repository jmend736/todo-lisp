#6.905 Task Parser Writeup

This part of the program is responsible for parsing a user's given
representation for a collection of `task`s schedule, validating it, and
packaging all this information up so that it can be used in the rest
of the system.


##Schema Definitions

###Task

In our system, an individual _task_ is described (loosely) in the following manner:

```scheme
('task
    ('id <id>)
    ('description <description>)
    ('duration <duration>)
    ('deadline <deadline>)
    ('duration <duration>)
    ('dependencies <dependencies>))
```
You can read the program technical specification more specifics,
but here's a brief description of each of the fields:


| Field Name       | Field Description                                                                                                           | Example                                                                                              |
|------------------|-----------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| `<id>`           | unique integer identifier for a task                                                                                        | `22`                                                                                                 |
| `<description>`  | description of a task                                                                                                       | `"This is not The Greatest Task in the World, no. This is just a tribute..."`                        |
| `<deadline>`     | string time representation that represents the fixed moment in time that a task must be completed by (`"YYYY-MM-DD-HH-MM"`) | `"1958-09-09-11-58"` <- This creates a deadline for the task that is September 9th 1958, at 11:58 AM |
| `<duration>`     | string time representation for how long a given task is supposed to last (`"XXd-XXh-XXm"`)                                  | `"11d-22h-63m"` <- This makes a task that will last 11 days, 22 hours, and 63 minutes.               |
| `<dependencies>` | comma delimited list of integer ids (possibly empty) of the tasks that must be completed before this task can be started    | `22, 44`                                                                                             |

###Schedule Options
A user is also able to define _schedule options_, which allows the user to the number of hours they're able to work on any given day of the week, etc.

```scheme
('schedule-options
    ('hours-per-day <hours-per-day>)
    ('time-per-task <time-per-task>)
    ('break-interval <break-interval>))
```

    Option Name     |                                                      Option Description                                                       |            Example
:------------------:|:-----------------------------------------------------------------------------------------------------------------------------:|:-----------------------------:
 `<hours-per-day>`  | 7 element list with time element strings, representing the amount of hours that you want to work on any given day of the week | `"8h, 8h, 5h, 3h, 2h, 0h, 0h"`
 `<time-per-task>`  | String time representation of the maximum amount of time per day that you want to spend doing a particular task (`"XXh-XXm"`) |          `"03h-15m"`
`<break-interval> ` |         string time representation of how long of a break the user wants in between work "chunks" (`"XXm-every-XXh"`)         |       `"45m-every-09h"`

##Task Parsing

The "official" setup way
