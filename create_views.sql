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
CREATE OR REPLACE VIEW SCHEMA_MAIN.V_COURSE_PLANNER
AS
SELECT
    ca.COURSE_ASSIGNMENT_TERM                       AS TERM,
    c.DEGREE_SHORT_NAME                             AS DEGREE_SHORT_NAME,
    s.SUBJECT_NR                                    AS SUBJECT_NR,
    s.SUBJECT_NAME                                  AS SUBJECT_NAME,
    s.SUBJECT_SEMESTER_LVL                          AS SEMESTER_LVL,
    s.SUBJECT_ELECTIVE                              AS ELECTIVE_FLAG,      -- P/W/Z
    s.SUBJECT_CURRICULUM                            AS CURRICULUM_HOURS,
    s.SUBJECT_SCHEDULE                              AS SCHEDULE_HOURS,
    ca.ACADEMIC_STAFF_ID                            AS ACADEMIC_STAFF_ID,
    st.FIRST_NAME                                   AS STAFF_FIRST_NAME,
    st.LAST_NAME                                    AS STAFF_LAST_NAME,
    st.IS_PROF                                      AS IS_PROF,
    st.FACULTY_SHORT_NAME                           AS STAFF_FACULTY_SHORT_NAME,
    f.FACULTY_NAME                                  AS STAFF_FACULTY_NAME,
    ca.TEACHING_HOURS                               AS TEACHING_HOURS,
    c.COURSE_COMMENT                                AS COURSE_COMMENT,
    s.SUBJECT_COMMENT                               AS SUBJECT_COMMENT,
    l.SUPERVISOR                                    AS SUPERVISOR_STAFF_ID
FROM SCHEMA_MAIN.COURSE_ASSIGNMENT ca
JOIN SCHEMA_MAIN.COURSE c
  ON c.SUBJECT_NR = ca.SUBJECT_NR
 AND c.DEGREE_SHORT_NAME = ca.DEGREE_SHORT_NAME
JOIN SCHEMA_MAIN.SUBJECT s
  ON s.SUBJECT_NR = c.SUBJECT_NR
JOIN SCHEMA_MAIN.ACADEMIC_STAFF st
  ON st.ACADEMIC_STAFF_ID = ca.ACADEMIC_STAFF_ID
LEFT JOIN SCHEMA_MAIN.FACULTY f
  ON f.FACULTY_SHORT_NAME = st.FACULTY_SHORT_NAME
LEFT JOIN SCHEMA_MAIN.LECTURER l
  ON l.ACADEMIC_STAFF_ID = st.ACADEMIC_STAFF_ID
;

--------------------------------------------------------------------------------
-- 2) Central timetable planning view
--    "Receives course offerings" + Export-View für erforderliche Daten
--    (Fokus: Kursangebot pro Term + minimaler Export-Datensatz)
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW SCHEMA_MAIN.V_TIMETABLE_OFFERINGS_EXPORT
AS
SELECT
    ca.COURSE_ASSIGNMENT_TERM                       AS TERM,
    c.DEGREE_SHORT_NAME                             AS DEGREE_SHORT_NAME,
    dp.DEGREE_NAME                                  AS DEGREE_NAME,
    dp.FACULTY_SHORT_NAME                           AS DEGREE_FACULTY_SHORT_NAME,
    f2.FACULTY_NAME                                 AS DEGREE_FACULTY_NAME,
    s.SUBJECT_NR                                    AS SUBJECT_NR,
    s.SUBJECT_NAME                                  AS SUBJECT_NAME,
    s.SUBJECT_SEMESTER_LVL                          AS SEMESTER_LVL,
    s.SUBJECT_ELECTIVE                              AS ELECTIVE_FLAG,
    s.SUBJECT_SCHEDULE                              AS SCHEDULE_HOURS,
    ca.ACADEMIC_STAFF_ID                            AS ACADEMIC_STAFF_ID,
    st.FIRST_NAME                                   AS STAFF_FIRST_NAME,
    st.LAST_NAME                                    AS STAFF_LAST_NAME,
    st.IS_PROF                                      AS IS_PROF,
    ca.TEACHING_HOURS                               AS TEACHING_HOURS
FROM SCHEMA_MAIN.COURSE_ASSIGNMENT ca
JOIN SCHEMA_MAIN.COURSE c
  ON c.SUBJECT_NR = ca.SUBJECT_NR
 AND c.DEGREE_SHORT_NAME = ca.DEGREE_SHORT_NAME
JOIN SCHEMA_MAIN.SUBJECT s
  ON s.SUBJECT_NR = c.SUBJECT_NR
JOIN SCHEMA_MAIN.ACADEMIC_STAFF st
  ON st.ACADEMIC_STAFF_ID = ca.ACADEMIC_STAFF_ID
LEFT JOIN SCHEMA_MAIN.DEGREE_PROGRAM dp
  ON dp.DEGREE_SHORT_NAME = c.DEGREE_SHORT_NAME
LEFT JOIN SCHEMA_MAIN.FACULTY f2
  ON f2.FACULTY_SHORT_NAME = dp.FACULTY_SHORT_NAME
;

--------------------------------------------------------------------------------
-- 3) Deputatsnachlass view
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


--------------------------------------------------------------------------------
-- Rechte (Beispiel)
-- Hinweis: "Write" auf Views mit Joins ist i.d.R. nicht updatable.
--          Schreibrechte gibt man auf die Basistabellen (INSERT/UPDATE/DELETE),
--          Views sind für Read/Export.
--------------------------------------------------------------------------------

-- Optional Rollen anlegen
CREATE ROLE ROLE_COURSE_PLANNER;
CREATE ROLE ROLE_CENTRAL_TIMETABLE;
CREATE ROLE ROLE_DEPUTATSNACHLASS;

-- Read/Export: SELECT auf Views
GRANT SELECT ON SCHEMA_MAIN.V_COURSE_PLANNER               TO ROLE ROLE_COURSE_PLANNER;
GRANT SELECT ON SCHEMA_MAIN.V_TIMETABLE_OFFERINGS_EXPORT   TO ROLE ROLE_CENTRAL_TIMETABLE;
GRANT SELECT ON SCHEMA_MAIN.V_DEPUTATSNACHLASS_WORKLOAD    TO ROLE ROLE_DEPUTATSNACHLASS;

-- Write (Planung): Basistabellen (typischer Umfang)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA_MAIN.SUBJECT           TO ROLE ROLE_COURSE_PLANNER;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA_MAIN.COURSE            TO ROLE ROLE_COURSE_PLANNER;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA_MAIN.COURSE_ASSIGNMENT TO ROLE ROLE_COURSE_PLANNER;

-- Central timetable: meistens Read-only auf Angebotsdaten
GRANT SELECT ON SCHEMA_MAIN.COURSE_ASSIGNMENT TO ROLE ROLE_CENTRAL_TIMETABLE;
GRANT SELECT ON SCHEMA_MAIN.COURSE           TO ROLE ROLE_CENTRAL_TIMETABLE;
GRANT SELECT ON SCHEMA_MAIN.SUBJECT          TO ROLE ROLE_CENTRAL_TIMETABLE;

-- Deputatsnachlass: Read/Write auf Workload je nach Use-Case
GRANT SELECT ON SCHEMA_MAIN.ACADEMIC_STAFF_WORKLOAD TO ROLE ROLE_DEPUTATSNACHLASS;

