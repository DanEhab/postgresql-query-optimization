CREATE TABLE Sailors(sid INT PRIMARY KEY, sname CHAR(20), rating INT, age REAL);

CREATE TABLE Boat(bid INT PRIMARY KEY, bname CHAR(20), color CHAR(10));

CREATE TABLE Reserves(sid INT REFERENCES Sailors, bid INT REFERENCES Boat, day date, PRIMARY KEY(sid,bid));


DROP TABLE IF EXISTS Reserves;
DROP TABLE IF EXISTS Boat;
DROP TABLE IF EXISTS Sailors;


select * from Sailors
select * from Boat
select * from Reserves




-- This prodcue 1006 rows!
Explain Analyze
select s.sname
from sailors s
where
s.sid in( select r.sid
from reserves r
where r.bid = 103 );

Explain Analyze
SELECT s.sname
FROM sailors s
JOIN reserves r ON s.sid = r.sid
WHERE r.bid = 103;



CREATE INDEX hash_reserves_bid_q1 ON reserves USING HASH (bid);

-- B+ Tree for join operations (foreign key relationships)
CREATE INDEX btree_sailors_sid_q1 ON sailors USING BTREE (sid);
CREATE INDEX btree_reserves_sid_q1 ON reserves USING BTREE (sid);

-- Covering index to avoid table lookup
CREATE INDEX btree_sailors_covering_q1 ON sailors USING BTREE (sid) INCLUDE (sname);
DROP INDEX IF EXISTS hash_reserves_bid_q1;
DROP INDEX IF EXISTS btree_sailors_sid_q1;
DROP INDEX IF EXISTS btree_reserves_sid_q1;
DROP INDEX IF EXISTS btree_sailors_covering_q1;




-- This produce 3318 rows !
Explain Analyze
select s.sname
from sailors s
where s.sid in ( select r.sid
from reserves r
where r. bid in (select b.bid
from boat b
where b.color = 'red'));


Explain Analyze
SELECT s.sname
FROM sailors s
WHERE EXISTS (
    SELECT 1
    FROM reserves r, boat b
    WHERE r.sid = s.sid 
      AND r.bid = b.bid 
      AND b.color = 'red'
	  Limit 1
);



CREATE INDEX btree_sailors_sid_q3 ON sailors (sid);

-- Hash indices for exact color matches (red/green)
CREATE INDEX hash_boat_color_red_q3 ON boat USING HASH (color) WHERE color = 'red';
CREATE INDEX hash_boat_color_green_q3 ON boat USING HASH (color) WHERE color = 'green';

-- BRIN for large table block-level filtering
CREATE INDEX brin_reserves_sid_q3 ON reserves USING BRIN (sid);
CREATE INDEX brin_reserves_bid_q3 ON reserves USING BRIN (bid);
CREATE INDEX brin_boat_bid_q3 ON boat USING BRIN (bid);

-- Composite B+ Tree for common access patterns
CREATE INDEX btree_reserves_composite_q3 ON reserves (sid, bid);

-- Partial Hash indices for specific colors (more efficient)
CREATE INDEX hash_boat_red_partial_q3 ON boat USING HASH (bid) WHERE color = 'red';
CREATE INDEX hash_boat_green_partial_q3 ON boat USING HASH (bid) where color = 'green'



-- This Produce 955 rows!
explain (analyze)
select s.sname
from sailors s, reserves r, boat b
where
s.sid = r.sid
and
r.bid = b.bid
and
b.color = 'red'
and
s.sid in ( select s2.sid
from sailors s2, boat b2, reserves r2
where s2.sid = r2.sid
and
r2.bid = b2.bid
and
b2.color = 'green');


explain (analyze)
SELECT s.sname
FROM sailors s, reserves r, boat b
WHERE s.sid = r.sid
  AND r.bid = b.bid
  AND b.color = 'red'
  AND EXISTS (
    SELECT 1
    FROM reserves r2, boat b2
    WHERE r2.sid = s.sid
      AND r2.bid = b2.bid
      AND b2.color = 'green'
	  Limit 1);