-- Query 4-B (schema4): directors of movies that cast a role that also appears in Titanic.

-- Original
select dir_fname, dir_lname
from director
where dir_id in (select dir_id
                 from movie_direction
                 where mov_id in (select mov_id
                                  from movie_cast
                                  where role = any (select role
                                                    from movie_cast
                                                    where mov_id in (select mov_id
                                                                     from movie
                                                                     where mov_title = 'Titanic'))));

-- Optimized: nested EXISTS with joins
SELECT d.dir_fname, d.dir_lname
FROM director d
WHERE EXISTS (SELECT 1
              FROM movie_direction md
              INNER JOIN movie_cast mc1 ON md.mov_id = mc1.mov_id
              WHERE md.dir_id = d.dir_id
                AND EXISTS (SELECT 1
                            FROM movie_cast mc2
                            INNER JOIN movie m ON mc2.mov_id = m.mov_id
                            WHERE mc2.role = mc1.role
                              AND m.mov_title = 'Titanic'));
