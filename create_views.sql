--------------------------------------------------------------------------------
-- VIEWS für deine "create_staging" / SCHEMA_MAIN Datenbank (DB2)
-- Basierend auf den Tabellen aus create_staging_fixed.sql:
-- FACULTY, SUBJECT, ACADEMIC_STAFF, ACADEMIC_STAFF_WORKLOAD,
-- DEGREE_PROGRAM, LECTURER, COURSE, COURSE_ASSIGNMENT
--------------------------------------------------------------------------------

-- Optional: eigenes Schema für Views (empfohlen)
-- (Wenn du alles in SCHEMA_MAIN halten willst, diese 2 Zeilen weglassen
--  und unten SCHEMA_MAIN durch SCHEMA_MAIN ersetzen.)
--  CREATE SCHEMA SCHEMA_MAIN;

--------------------------------------------------------------------------------
-- 1) Course planner view (Deputatsplanner)
--    Planung + Zuordnung Lehrende + "Liste der Lectures" + Export-geeignet
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW SCHEMA_MAIN.V_COURSE_PLANNER AS
SELECT
  t.COURSE_ASSIGNMENT_TERM        AS TERM,
  c.DEGREE_SHORT_NAME             AS DEGREE_SHORT_NAME,
  c.SUBJECT_NR                    AS SUBJECT_NR,

  s.SUBJECT_NAME                  AS SUBJECT_NAME,
  s.SUBJECT_SEMESTER_LVL          AS SEMESTER_LVL,
  s.SUBJECT_ELECTIVE              AS ELECTIVE_FLAG,
  s.SUBJECT_SCHEDULE              AS SCHEDULE_HOURS,

  ca.ACADEMIC_STAFF_ID            AS ACADEMIC_STAFF_ID,
  st.FIRST_NAME                   AS STAFF_FIRST_NAME,
  st.LAST_NAME                    AS STAFF_LAST_NAME,
  st.FACULTY_SHORT_NAME           AS STAFF_FACULTY_SHORT_NAME,

  ca.TEACHING_HOURS               AS TEACHING_HOURS

FROM SCHEMA_MAIN.COURSE c
JOIN SCHEMA_MAIN.SUBJECT s
  ON s.SUBJECT_NR = c.SUBJECT_NR

-- alle existierenden Semester
CROSS JOIN (
  SELECT DISTINCT COURSE_ASSIGNMENT_TERM
  FROM SCHEMA_MAIN.COURSE_ASSIGNMENT
) t

-- Assignment optional pro Kurs + Semester
LEFT JOIN SCHEMA_MAIN.COURSE_ASSIGNMENT ca
  ON ca.SUBJECT_NR = c.SUBJECT_NR
 AND ca.DEGREE_SHORT_NAME = c.DEGREE_SHORT_NAME
 AND ca.COURSE_ASSIGNMENT_TERM = t.COURSE_ASSIGNMENT_TERM

LEFT JOIN SCHEMA_MAIN.ACADEMIC_STAFF st
  ON st.ACADEMIC_STAFF_ID = ca.ACADEMIC_STAFF_ID;




--------------------------------------------------------------------------------
-- 2) Deputatsnachlass view
--    "Working hours of past semester" = Reduktion/Workload je Semester + Person
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW SCHEMA_MAIN.V_DEPUTATSNACHLASS_WORKLOAD
AS
SELECT
    w.SEMESTER_NR                                   AS SEMESTER_NR,
    w.ACADEMIC_STAFF_ID                             AS ACADEMIC_STAFF_ID,
    st.FIRST_NAME                                   AS STAFF_FIRST_NAME,
    st.LAST_NAME                                    AS STAFF_LAST_NAME,
    st.IS_PROF                                      AS IS_PROF,
    st.FACULTY_SHORT_NAME                           AS STAFF_FACULTY_SHORT_NAME,
    f.FACULTY_NAME                                  AS STAFF_FACULTY_NAME,
    w.ACADEMIC_STAFF_ROLE                           AS STAFF_ROLE,
    w.ACADEMIC_STAFF_REDUCTION                      AS REDUCTION_HOURS
FROM SCHEMA_MAIN.ACADEMIC_STAFF_WORKLOAD w
JOIN SCHEMA_MAIN.ACADEMIC_STAFF st
  ON st.ACADEMIC_STAFF_ID = w.ACADEMIC_STAFF_ID
LEFT JOIN SCHEMA_MAIN.FACULTY f
  ON f.FACULTY_SHORT_NAME = st.FACULTY_SHORT_NAME
;


