-- Query 2-A (schema2): projects whose department is managed by employee1, or that employee1 works on.

-- Original
select distinct pnumber
from project
where pnumber in
      (select pnumber
       from project, department d, employee e
       where e.dno = d.dnumber
         and d.mgr_snn = ssn
         and e.lname = 'employee1')
   or pnumber in
      (select pno
       from works_on, employee
       where essn = ssn and lname = 'employee1');

-- Optimized: both IN lists rewritten as EXISTS
SELECT DISTINCT p.pnumber
FROM project AS p
WHERE EXISTS (SELECT 1
              FROM department d
              JOIN employee e ON e.dno = d.dnumber
              WHERE d.mgr_snn = e.ssn
                AND e.lname = 'employee1')
   OR EXISTS (SELECT 1
              FROM works_on w
              JOIN employee e ON e.ssn = w.essn
              WHERE w.pno = p.pnumber
                AND e.lname = 'employee1');
