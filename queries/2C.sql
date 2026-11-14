-- Query 2-C (schema2): employees with a dependent who has the same first name and sex.

-- Original
select e.fname, e.lname
from employee as e
where e.ssn in (select essn
                from dependent as d
                where e.fname = d.dependent_name
                  and e.sex = d.sex);

-- Optimized: correlated EXISTS
SELECT e.fname, e.lname
FROM employee e
WHERE EXISTS (SELECT 1
              FROM dependent d
              WHERE d.essn = e.ssn
                AND d.dependent_name = e.fname
                AND d.sex = e.sex);
