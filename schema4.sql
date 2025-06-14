CREATE TABLE Movie(mov_id INT PRIMARY KEY, mov_title CHAR(50), mov_year INT, mov_time INT, mov_lang CHAR(50), mov_dt_rel date, mov_rel_country CHAR(5));

CREATE TABLE Reviewer(rev_id INT PRIMARY KEY, rev_name CHAR(30));

CREATE TABLE Genres(gen_id INT PRIMARY KEY, gen_title CHAR(20));

CREATE TABLE Actor(act_id INT PRIMARY KEY, act_fname CHAR(20), act_lname CHAR(20), act_gender CHAR(1));

CREATE TABLE Director(dir_id INT PRIMARY KEY, dir_fname CHAR(20), dir_lname CHAR(20));

CREATE TABLE movie_direction(dir_id INT REFERENCES Director, mov_id INT REFERENCES Movie, PRIMARY KEY(dir_id,mov_id));

CREATE TABLE movie_cast(act_id INT REFERENCES Actor, mov_id INT REFERENCES Movie, role CHAR(30), PRIMARY KEY(act_id, mov_id));

CREATE TABLE movie_genres(mov_id INT REFERENCES Movie, gen_id INT REFERENCES genres, PRIMARY KEY(mov_id,gen_id));

CREATE TABLE Rating(mov_id INT REFERENCES Movie, rev_id INT REFERENCES Reviewer, rev_stars INT, num_o_ratings INT, PRIMARY KEY(mov_id,rev_id));



DROP TABLE IF EXISTS movie_direction;
DROP TABLE IF EXISTS movie_cast;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS Rating;

DROP TABLE IF EXISTS Director;
DROP TABLE IF EXISTS Actor;
DROP TABLE IF EXISTS Genres;
DROP TABLE IF EXISTS Reviewer;
DROP TABLE IF EXISTS Movie;

select * from movie_cast


-- Primary approach with B+ trees
CREATE INDEX idx_director_name_btree ON director USING BTREE (dir_fname, dir_lname);
CREATE INDEX idx_movie_direction_dir_btree ON movie_direction USING BTREE (dir_id);
CREATE INDEX idx_movie_direction_mov_btree ON movie_direction USING BTREE (mov_id);
CREATE INDEX idx_movie_pk_btree ON movie Using BTREE (mov_id)

/* Drop the B-tree indexes for the director-movie tables */

DROP INDEX IF EXISTS idx_director_name_btree;
DROP INDEX IF EXISTS idx_movie_direction_dir_btree;
DROP INDEX IF EXISTS idx_movie_direction_mov_btree;
DROP INDEX IF EXISTS idx_movie_pk_btree;



-- Hash approach for exact matches
CREATE INDEX idx_director_name_hash ON director USING HASH (dir_fname)
CREATE INDEX idx_director_name_hash2 ON director USING HASH (dir_lname)
CREATE INDEX idx_movie_direction_dir_hash ON movie_direction USING HASH (dir_id);
CREATE INDEX idx_movie_direction_mov_hash ON movie_direction USING HASH (mov_id);
CREATE INDEX idx_movie_pk_hash ON movie using hash(mov_id)



DROP INDEX IF EXISTS idx_director_name_hash;
DROP INDEX IF EXISTS idx_movie_direction_dir_hash;
DROP INDEX IF EXISTS idx_movie_direction_mov_hash;
DROP INDEX IF EXISTS idx_movie_pk_hash;


-- BRIN approach (mainly useful if data has natural ordering)
CREATE INDEX idx_director_name_brin ON director USING BRIN (dir_fname, dir_lname);
CREATE INDEX idx_movie_direction_dir_brin ON movie_direction USING BRIN (dir_id);
CREATE INDEX idx_movie_direction_mov_brin ON movie_direction USING BRIN (mov_id);
CREATE INDEX idx_movie_pk_brin ON movie using BRIN (mov_id)


DROP INDEX IF EXISTS idx_director_name_brin;
DROP INDEX IF EXISTS idx_movie_direction_dir_brin;
DROP INDEX IF EXISTS idx_movie_direction_mov_brin;
DROP INDEX IF EXISTS idx_movie_pk_brin;


-- Hybrid approach for maximum optimization
-- Hash for exact equality lookups
CREATE INDEX idx_director_name_hash ON director USING HASH (dir_fname)
CREATE INDEX idx_director_name_hash2 ON director USING HASH (dir_lname)
-- B+ Tree for join columns (supports range operations and sorting)
CREATE INDEX idx_movie_direction_composite_btree ON movie_direction USING BTREE (dir_id, mov_id);
-- Hash for final movie lookup
CREATE INDEX idx_movie_pk_hash ON movie USING HASH (mov_id);
-- Optional: Covering index to avoid table lookups entirely
CREATE INDEX idx_movie_covering_btree ON movie USING BTREE (mov_id) include (mov_title)


/* Drop the mixed (hybrid) indexes listed */

/* HASH indexes on director */
DROP INDEX IF EXISTS idx_director_name_hash;
DROP INDEX IF EXISTS idx_director_name_hash2;
/* Composite B-tree on movie_direction */
DROP INDEX IF EXISTS idx_movie_direction_composite_btree;
/* HASH index on movie PK */
DROP INDEX IF EXISTS idx_movie_pk_hash;
/* Covering B-tree on movie (mov_id, mov_title) */
DROP INDEX IF EXISTS idx_movie_covering_btree;



-- 300 rows produced
EXPLAIN ANALYZE
select *
from actor
where act_id in(
select act_id
from movie_cast
where mov_id in(
select mov_id
from movie
where mov_title ='Toy Story'));


 EXPLAIN ANALYZE
SELECT a.*
FROM actor a
WHERE a.act_id IN (
    SELECT DISTINCT mc.act_id
    FROM movie_cast mc
    INNER JOIN movie m ON mc.mov_id = m.mov_id
    WHERE m.mov_title = 'Toy Story'
);


--6000 rows produced
 EXPLAIN ANALYZE
select dir_fname, dir_lname
from director
where dir_id in(
select dir_id
from movie_direction
where mov_id in(
select mov_id
from movie_cast
where role = any( select role
from movie_cast
where mov_id in(
select mov_id
from movie
where
mov_title = 'Titanic'))));



--query2 optimzed
 EXPLAIN ANALYZE
SELECT d.dir_fname, d.dir_lname
FROM director d
WHERE EXISTS (
    SELECT 1
    FROM movie_direction md
    INNER JOIN movie_cast mc1 ON md.mov_id = mc1.mov_id
    WHERE md.dir_id = d.dir_id
      AND EXISTS (
          SELECT 1
          FROM movie_cast mc2
          INNER JOIN movie m ON mc2.mov_id = m.mov_id
          WHERE mc2.role = mc1.role
            AND m.mov_title = 'Titanic'
))


--516 rows produced
EXPLAIN ANALYZE
select mov_title
from movie
where mov_id in (
select mov_id
from movie_direction
where dir_id =
(select dir_id
from director
where dir_fname = 'Quentin'
and
dir_lname = 'Tarantino'));


EXPLAIN ANALYZE
SELECT m.mov_title`
FROM movie m
INNER JOIN movie_direction md ON m.mov_id = md.mov_id
INNER JOIN director d ON md.dir_id = d.dir_id
WHERE d.dir_fname = 'Quentin' 
  AND d.dir_lname = 'Tarantino'



