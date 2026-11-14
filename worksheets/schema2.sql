CREATE TABLE Employee(Fname CHAR(20), Minit CHAR(10), Lname CHAR(20), ssn INT PRIMARY KEY, Bdate date, address CHAR(20), sex CHARACTER(1), salary INT, Super_snn INT REFERENCES Employee(ssn), dno INT);

CREATE TABLE Department(Dname CHAR(20), Dnumber INT PRIMARY KEY, Mgr_snn int REFERENCES employee, Mgr_start_date date );

CREATE TABLE Dept_locations(Dnumber integer REFERENCES Department, Dlocation CHAR(20), PRIMARY KEY(Dnumber,Dlocation));

CREATE TABLE Project(Pname CHAR(20), Pnumber INT PRIMARY KEY, Plocation CHAR(50), Dnumber INT REFERENCES Department);

CREATE TABLE Works_on(Essn int REFERENCES Employee, Pno int REFERENCES Project, Hours int, PRIMARY KEY(Essn,Pno));

CREATE TABLE Dependent(Essn INT REFERENCES Employee, Dependent_name CHAR(20), sex CHARACTER(1), Bdate date, Relationship CHAR(20), PRIMARY KEY(Essn, Dependent_name));


DROP TABLE IF EXISTS Works_on;
DROP TABLE IF EXISTS Dependent;
DROP TABLE IF EXISTS Dept_locations;
DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Employee;



select * from Employee
select * from Department
select * from Dept_locations
select * from Project





-- 9200 rows:
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
select distinct pnumber
from project
where pnumber in
(select pnumber
from project, department d, employee e
where e.dno = d.dnumber
and
d.mgr_snn = ssn
and
e.lname = 'employee1' )
or
pnumber in
(select pno
from works_on, employee
where essn = ssn and lname = 'employee1' );



EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT DISTINCT p.pnumber
FROM   project AS p
WHERE  EXISTS (                          -- first IN-list rewritten
        SELECT 1
        FROM   department  d
        JOIN   employee    e ON e.dno = d.dnumber
        WHERE  d.mgr_snn = e.ssn          --   same condition
          AND  e.lname  = 'employee1'     --   but no link to p
      )
   OR  EXISTS (                          -- second IN-list rewritten
        SELECT 1
        FROM   works_on w
        JOIN   employee  e ON e.ssn = w.essn
        WHERE  w.pno   = p.pnumber        --   correlated to p
          AND  e.lname = 'employee1'
      );

\-- Drop all prior indexes
DROP INDEX IF EXISTS idx_employee_salary, idx_employee_dno, idx_employee_d5;
	

--45 rows
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
select lname, fname
from employee
where salary > all (
select salary
from employee
where dno = 5 );

EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT  e.lname,
        e.fname
FROM    employee e
WHERE   e.salary >
        ( SELECT MAX(salary)                     -- single scalar value
          FROM   employee
          WHERE  dno = 5 );




-- B+ Tree for joins
CREATE INDEX idx_emp_ssn ON employee (ssn);
CREATE INDEX idx_dep_essn ON dependent (essn);

-- Composite for multi-condition filtering
CREATE INDEX idx_emp_fname_sex ON employee (fname, sex);
CREATE INDEX idx_dep_name_sex ON dependent (dependent_name, sex)



--701 row
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
select e.fname, e.lname
from employee as e
where e.ssn in (
select essn
from dependent as d
where e.fname = d.dependent_name
and
e.sex = d.sex );



Explain Analyze
SELECT e.fname, e.lname
FROM employee e
WHERE EXISTS (
  SELECT 1
  FROM dependent d
  WHERE d.essn = e.ssn
    AND d.dependent_name = e.fname
    AND d.sex = e.sex
);






--1500 row
Explain Analyze
select fname, lname
from employee
where exists ( select *
from dependent
where ssn = essn );


Explain Analyze
SELECT e.fname, e.lname
FROM employee e
WHERE EXISTS (
  SELECT 1
  FROM dependent
  where ssn = essn
);


-- 1. B+ Tree index on salary
CREATE INDEX idx_employee_salary_btree ON employee(salary);
-- 2. Hash index on dno
CREATE INDEX idx_employee_dno_hash ON employee USING hash(dno);
CREATE INDEX idx_employee_salary_brin ON employee USING brin(salary);
-- 4. Mixed composite B-tree index on (dno, salary)
CREATE INDEX idx_employee_dno_salary_btree ON employee(dno, salary);



DROP INDEX IF EXISTS idx_employee_salary_btree;
DROP INDEX IF EXISTS idx_employee_dno_hash;
DROP INDEX IF EXISTS idx_employee_salary_brin;
DROP INDEX IF EXISTS idx_employee_dno_salary_btree



--150 row
Explain Analyze
select dnumber, count(*)
from department, employee
where dnumber = dno
and
salary > 40000
and
dno in (
select dno
from employee
group by dno
having count (*) > 5)
group by dnumber;



Explain Analyze
SELECT dnumber, COUNT(*) 
FROM department 
JOIN employee ON department.dnumber = employee.dno 
WHERE salary > 40000 
GROUP BY dnumber 
HAVING COUNT(*) > 5;