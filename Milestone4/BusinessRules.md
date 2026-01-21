# Business Rules 

- **All attributes are NOT NULL**, except:
  - `SCHEMA_MAIN.SUBJECT.SUBJECT_COMMENT`
  - `SCHEMA_MAIN.ACADEMIC_STAFF.ACADEMIC_STAFF_COMMENT`
  - `SCHEMA_MAIN.LECTURER.SUPERVISOR`
  - `SCHEMA_MAIN.COURSE.COURSE_COMMENT`
  - `SCHEMA_MAIN.COURSE_ASSIGNMENT.TEACHING_HOURS`

- **Term validity (semester format) in relevant tables:**
  - `SCHEMA_MAIN.COURSE_ASSIGNMENT.COURSE_ASSIGNMENT_TERM` must be a valid term format, enforced by:
    - `COURSE_ASSIGNMENT_TERM LIKE 'WS%' OR COURSE_ASSIGNMENT_TERM LIKE 'SS%'`
  - `SCHEMA_MAIN.ACADEMIC_STAFF_WORKLOAD.SEMESTER_NR` must match the same semester format  
    - *(not enforced by a CHECK constraint in the current DDL, but should follow the same convention)*

- **A course assignment can only exist with a valid academic staff member:**
  - `SCHEMA_MAIN.COURSE_ASSIGNMENT.ACADEMIC_STAFF_ID` references `SCHEMA_MAIN.ACADEMIC_STAFF(ACADEMIC_STAFF_ID)`

- **A course assignment can only be made for an existing course (subject + degree program):**
  - `(SCHEMA_MAIN.COURSE_ASSIGNMENT.SUBJECT_NR, SCHEMA_MAIN.COURSE_ASSIGNMENT.DEGREE_SHORT_NAME)`
    references `(SCHEMA_MAIN.COURSE.SUBJECT_NR, SCHEMA_MAIN.COURSE.DEGREE_SHORT_NAME)`

- **A course can only exist for an existing subject:**
  - `SCHEMA_MAIN.COURSE.SUBJECT_NR` references `SCHEMA_MAIN.SUBJECT(SUBJECT_NR)`

- **A course can only exist for an existing degree program:**
  - `SCHEMA_MAIN.COURSE.DEGREE_SHORT_NAME` references `SCHEMA_MAIN.DEGREE_PROGRAM(DEGREE_SHORT_NAME)`

- **Only an existing academic staff member can have a workload reduction:**
  - `SCHEMA_MAIN.ACADEMIC_STAFF_WORKLOAD.ACADEMIC_STAFF_ID`
    references `SCHEMA_MAIN.ACADEMIC_STAFF(ACADEMIC_STAFF_ID)`

- **Only an existing academic staff member can be a lecturer:**
  - `SCHEMA_MAIN.LECTURER.ACADEMIC_STAFF_ID`
    references `SCHEMA_MAIN.ACADEMIC_STAFF(ACADEMIC_STAFF_ID)`

- **Uniqueness constraints (primary keys):**
  - `SUBJECT.SUBJECT_NR` is unique
  - `ACADEMIC_STAFF.ACADEMIC_STAFF_ID` is unique
  - `FACULTY.FACULTY_SHORT_NAME` is unique
  - `DEGREE_PROGRAM.DEGREE_SHORT_NAME` is unique
  - Composite uniqueness:
    - `COURSE (SUBJECT_NR, DEGREE_SHORT_NAME)` is unique
    - `COURSE_ASSIGNMENT (SUBJECT_NR, COURSE_ASSIGNMENT_TERM, ACADEMIC_STAFF_ID)` is unique
    - `ACADEMIC_STAFF_WORKLOAD (SEMESTER_NR, ACADEMIC_STAFF_ID)` is unique
