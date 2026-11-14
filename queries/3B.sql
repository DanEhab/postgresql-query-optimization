-- Query 3-B (schema3): sailors who reserved a red boat.

-- Original
select s.sname
from sailors s
where s.sid in (select r.sid
                from reserves r
                where r.bid in (select b.bid
                                from boat b
                                where b.color = 'red'));

-- Optimized: one correlated EXISTS that stops at the first red reservation
SELECT s.sname
FROM sailors s
WHERE EXISTS (SELECT 1
              FROM reserves r, boat b
              WHERE r.sid = s.sid
                AND r.bid = b.bid
                AND b.color = 'red'
              LIMIT 1);
