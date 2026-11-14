-- Query 3-C (schema3): sailors who reserved both a red and a green boat.

-- Original
select s.sname
from sailors s, reserves r, boat b
where s.sid = r.sid
  and r.bid = b.bid
  and b.color = 'red'
  and s.sid in (select s2.sid
                from sailors s2, boat b2, reserves r2
                where s2.sid = r2.sid
                  and r2.bid = b2.bid
                  and b2.color = 'green');

-- Optimized: correlated EXISTS, without the extra join to sailors
SELECT s.sname
FROM sailors s, reserves r, boat b
WHERE s.sid = r.sid
  AND r.bid = b.bid
  AND b.color = 'red'
  AND EXISTS (SELECT 1
              FROM reserves r2, boat b2
              WHERE r2.sid = s.sid
                AND r2.bid = b2.bid
                AND b2.color = 'green'
              LIMIT 1);
