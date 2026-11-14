-- Query 1-A (schema1): every MET student, with the sections they took in semester 5 of 2025,
-- and every semester-5 2025 section even if no MET student took it.

-- Original
select *
from (select *
      from student
      where department = 'MET') as MET_student
full outer join
     (select *
      from takes t inner join section s
        on t.section_id = s.section_id
      where semester = 5
        and year = 2025) as sem5_student
  on MET_student.id = sem5_student.student_id;

-- Optimized: list the columns once instead of SELECT * over both sides
SELECT COALESCE(met_students.id, sem5_takes.student_id) AS id,
       met_students.name, met_students.tot_credit, met_students.department, met_students.advisor_id,
       sem5_takes.section_id, sem5_takes.grade, sem5_takes.semester, sem5_takes.year,
       sem5_takes.instructor_id, sem5_takes.course_id, sem5_takes.classroom_building, sem5_takes.classroom_room_no
FROM (SELECT s.* FROM student s WHERE s.department = 'MET') AS met_students
FULL OUTER JOIN
     (SELECT t.student_id, t.section_id, t.grade,
             sec.semester, sec.year, sec.instructor_id, sec.course_id,
             sec.classroom_building, sec.classroom_room_no
      FROM takes t
      INNER JOIN section sec ON t.section_id = sec.section_id
      WHERE sec.semester = 5 AND sec.year = 2025) AS sem5_takes
  ON met_students.id = sem5_takes.student_id;
