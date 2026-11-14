-- Query 2-D (schema2): employees who have dependents.

-- Original
select fname, lname
from employee
where exists (select *
              from dependent
              where ssn = essn);

-- Optimized: EXISTS (SELECT 1) instead of SELECT *
SELECT e.fname, e.lname
FROM employee e
WHERE EXISTS (SELECT 1
              FROM dependent
              WHERE ssn = essn);
