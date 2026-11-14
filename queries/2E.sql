-- Query 2-E (schema2): for each department with more than five employees, the number of its
-- employees who earn more than 40,000.
-- The project description writes "dno = (subquery)", which PostgreSQL rejects here because
-- the subquery returns all 150 departments, so the team ran it with "dno in (subquery)".

-- Original
select dnumber, count(*)
from department, employee
where dnumber = dno
  and salary > 40000
  and dno in (select dno
              from employee
              group by dno
              having count(*) > 5)
group by dnumber;

-- Optimized: one join and a HAVING clause instead of the grouped subquery
SELECT dnumber, COUNT(*)
FROM department
JOIN employee ON department.dnumber = employee.dno
WHERE salary > 40000
GROUP BY dnumber
HAVING COUNT(*) > 5;
