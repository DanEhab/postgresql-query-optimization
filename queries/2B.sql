-- Query 2-B (schema2): employees who earn more than everyone in department 5.

-- Original
select lname, fname
from employee
where salary > all (select salary
                    from employee
                    where dno = 5);

-- Optimized: compare with a single MAX instead of every salary
SELECT e.lname, e.fname
FROM employee e
WHERE e.salary > (SELECT MAX(salary)
                  FROM employee
                  WHERE dno = 5);
