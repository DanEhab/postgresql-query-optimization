CREATE TABLE department(dep_name VARCHAR(20) PRIMARY KEY, building NUMERIC, budget NUMERIC);

CREATE TABLE instructor(ID INT PRIMARY KEY, name VARCHAR(20), salary NUMERIC, dep_name VARCHAR(20) REFERENCES department);

CREATE TABLE classroom(building INT, room_number INT, capacity NUMERIC, PRIMARY KEY(building, room_number), UNIQUE(building), UNIQUE(room_number));

CREATE TABLE time_slot(id INT PRIMARY KEY, day VARCHAR(10), start time, end_time time);

CREATE TABLE student(id INT PRIMARY KEY, name VARCHAR(20), tot_credit INT, department VARCHAR(20) REFERENCES department, advisor_id INT REFERENCES instructor);

CREATE TABLE course(course_id INT PRIMARY KEY, title VARCHAR(20), credits INT, department VARCHAR(20) REFERENCES department);

CREATE TABLE pre_requiste(course_id INT, prereq_id INT,PRIMARY KEY(course_id, prereq_id));

CREATE TABLE section(section_id INT PRIMARY KEY, semester INT, year INT, instructor_id INT REFERENCES instructor, course_id INT REFERENCES course,classroom_building INT REFERENCES classroom(building), classroom_room_no INT REFERENCES classroom(room_number));

CREATE TABLE takes(student_id INT REFERENCES student, section_id INT REFERENCES section, grade real, PRIMARY KEY(student_id, section_id));

CREATE TABLE section_time(time_slot INT REFERENCES time_slot, section_id INT REFERENCES section, PRIMARY KEY(time_slot, section_id));


DROP TABLE IF EXISTS section_time CASCADE;
DROP TABLE IF EXISTS takes CASCADE;
DROP TABLE IF EXISTS section CASCADE;
DROP TABLE IF EXISTS pre_requiste CASCADE;
DROP TABLE IF EXISTS course CASCADE;
DROP TABLE IF EXISTS student CASCADE;
DROP TABLE IF EXISTS time_slot CASCADE;
DROP TABLE IF EXISTS classroom CASCADE;
DROP TABLE IF EXISTS instructor CASCADE;
DROP TABLE IF EXISTS department CASCADE;


EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
select *
from (select *
from student
where
department = 'MET') as MET_student
full outer join
(select *
from takes t inner join section s
on t.section_id = s.section_id
where semester = 5
and
year = 2025) as sem5_student
on MET_student.id = sem5_student.student_id;



DROP INDEX idx_student_id_brin, idx_section_id_brin, idx_takes_student_brin, idx_takes_section_brin;

CREATE INDEX idx_student_dept_btree ON student(department);
CREATE INDEX idx_section_sem_hash ON section USING HASH(semester);
CREATE INDEX idx_section_year_hash ON section USING HASH(year);
CREATE INDEX idx_takes_student_brin ON takes USING BRIN(student_id);
CREATE INDEX idx_takes_section_btree ON takes(section_id);




-- ALTERNATIVE QUERY (Same Results, Similar Performance)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT 
    COALESCE(met_students.id, sem5_takes.student_id) as id,
    met_students.name,
    met_students.tot_credit,
    met_students.department,
    met_students.advisor_id,
    sem5_takes.section_id,
    sem5_takes.grade,
    sem5_takes.semester,
    sem5_takes.year,
    sem5_takes.instructor_id,
    sem5_takes.course_id,
    sem5_takes.classroom_building,
    sem5_takes.classroom_room_no
FROM 
    (SELECT s.* FROM student s WHERE s.department = 'MET') AS met_students
FULL OUTER JOIN 
    (SELECT t.student_id, t.section_id, t.grade, 
            sec.semester, sec.year, sec.instructor_id, sec.course_id,
            sec.classroom_building, sec.classroom_room_no
     FROM takes t 
     INNER JOIN section sec ON t.section_id = sec.section_id
     WHERE sec.semester = 5 AND sec.year = 2025) AS sem5_takes
ON met_students.id = sem5_takes.student_id;

