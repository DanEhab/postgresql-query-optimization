-- Query 4-A (schema4): all information about the actors in the movie Toy Story.

-- Original
select *
from actor
where act_id in (select act_id
                 from movie_cast
                 where mov_id in (select mov_id
                                  from movie
                                  where mov_title = 'Toy Story'));

-- Optimized: one join inside the IN instead of two nested subqueries
SELECT a.*
FROM actor a
WHERE a.act_id IN (SELECT DISTINCT mc.act_id
                   FROM movie_cast mc
                   INNER JOIN movie m ON mc.mov_id = m.mov_id
                   WHERE m.mov_title = 'Toy Story');
