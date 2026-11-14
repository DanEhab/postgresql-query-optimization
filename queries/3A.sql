-- Query 3-A (schema3): sailors who reserved boat 103.

-- Original
select s.sname
from sailors s
where s.sid in (select r.sid
                from reserves r
                where r.bid = 103);

-- Optimized: a join (a sailor can reserve a boat only once, so there are no duplicates)
SELECT s.sname
FROM sailors s
JOIN reserves r ON s.sid = r.sid
WHERE r.bid = 103;
