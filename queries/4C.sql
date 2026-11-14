-- Query 4-C (schema4): titles of the movies directed by Quentin Tarantino.

-- Original
select mov_title
from movie
where mov_id in (select mov_id
                 from movie_direction
                 where dir_id = (select dir_id
                                 from director
                                 where dir_fname = 'Quentin'
                                   and dir_lname = 'Tarantino'));

-- Optimized: two joins instead of nested subqueries
SELECT m.mov_title
FROM movie m
INNER JOIN movie_direction md ON m.mov_id = md.mov_id
INNER JOIN director d ON md.dir_id = d.dir_id
WHERE d.dir_fname = 'Quentin'
  AND d.dir_lname = 'Tarantino';
