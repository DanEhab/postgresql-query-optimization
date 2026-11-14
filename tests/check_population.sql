-- Checks that the populated databases meet the requirements of the project description.
-- Run with: psql -v ON_ERROR_STOP=1 -f tests/check_population.sql

\c schema1
DO $$
DECLARE c_min int; c_max int; i_min int; i_max int; s_min int;
BEGIN
  IF (SELECT count(*) FROM department) <> 60 THEN RAISE EXCEPTION 'schema1: expected 60 departments'; END IF;
  SELECT min(n), max(n) INTO c_min, c_max FROM (SELECT count(*) n FROM course GROUP BY department) x;
  SELECT min(n), max(n) INTO i_min, i_max FROM (SELECT count(*) n FROM instructor GROUP BY dep_name) x;
  SELECT min(n) INTO s_min FROM (SELECT count(*) n FROM student GROUP BY department) x;
  IF c_min < 20 OR c_max > 45 THEN RAISE EXCEPTION 'schema1: departments must offer 20 to 45 courses (found % to %)', c_min, c_max; END IF;
  IF i_min < 10 OR i_max > 35 THEN RAISE EXCEPTION 'schema1: departments must have 10 to 35 instructors (found % to %)', i_min, i_max; END IF;
  IF s_min < 1100 THEN RAISE EXCEPTION 'schema1: every department needs at least 1100 students (found %)', s_min; END IF;
  RAISE NOTICE 'schema1 OK: 60 departments, % to % courses and % to % instructors each, at least % students each', c_min, c_max, i_min, i_max, s_min;
END $$;

\c schema2
DO $$
BEGIN
  IF (SELECT count(*) FROM employee) <> 16000 THEN RAISE EXCEPTION 'schema2: expected 16000 employees'; END IF;
  IF (SELECT count(*) FROM department) <> 150 THEN RAISE EXCEPTION 'schema2: expected 150 departments'; END IF;
  IF (SELECT count(*) FROM dept_locations) <> 150 THEN RAISE EXCEPTION 'schema2: expected 150 department locations'; END IF;
  IF (SELECT count(*) FROM project) <> 9200 THEN RAISE EXCEPTION 'schema2: expected 9200 projects'; END IF;
  RAISE NOTICE 'schema2 OK: 16000 employees, 150 departments, 150 department locations, 9200 projects';
END $$;

\c schema3
DO $$
BEGIN
  IF (SELECT count(*) FROM sailors) <> 19000 THEN RAISE EXCEPTION 'schema3: expected 19000 sailors'; END IF;
  IF (SELECT count(*) FROM boat) <> 3000 THEN RAISE EXCEPTION 'schema3: expected 3000 boats'; END IF;
  IF (SELECT count(*) FROM reserves) < 35000 THEN RAISE EXCEPTION 'schema3: expected at least 35000 reservations'; END IF;
  RAISE NOTICE 'schema3 OK: 19000 sailors, 3000 boats, % reservations', (SELECT count(*) FROM reserves);
END $$;

\c schema4
DO $$
BEGIN
  IF (SELECT count(*) FROM movie) <> 100000 THEN RAISE EXCEPTION 'schema4: expected 100000 movies'; END IF;
  IF (SELECT count(*) FROM actor) <> 120000 THEN RAISE EXCEPTION 'schema4: expected 120000 actors'; END IF;
  IF (SELECT count(*) FROM director) <> 6000 THEN RAISE EXCEPTION 'schema4: expected 6000 directors'; END IF;
  RAISE NOTICE 'schema4 OK: 100000 movies, 120000 actors, 6000 directors';
END $$;
