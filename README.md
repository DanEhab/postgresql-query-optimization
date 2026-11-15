<div align="center">

# 🗄️ PostgreSQL Query Optimization: Execution Plans & Indexes

**Four PostgreSQL databases filled with hundreds of thousands of generated rows, 12 SQL queries analysed with `EXPLAIN ANALYZE` under no index, B+ tree, hash, BRIN and mixed indexes, and a faster rewrite of each query that returns exactly the same result.**

[![CI](https://github.com/DanEhab/postgresql-query-optimization/actions/workflows/ci.yml/badge.svg)](https://github.com/DanEhab/postgresql-query-optimization/actions/workflows/ci.yml)
![Database](https://img.shields.io/badge/Database-PostgreSQL%2016-336791?logo=postgresql&logoColor=white)
![Java](https://img.shields.io/badge/Data%20generation-Java%20%C2%B7%20JDBC-ed8b00?logo=openjdk&logoColor=white)
![Course](https://img.shields.io/badge/Course-Databases%20II-1f6feb)
![Semester](https://img.shields.io/badge/Semester-Spring%202025-8957e5)
![Grade](https://img.shields.io/badge/Course%20grade-A%2B-success)

</div>

---

## The project

For each query, the work followed the same steps:

1. **Generate data** with Java and JDBC, so that the query returns a realistic, non-trivial result (hundreds or thousands of rows, never an empty set).
2. **Analyse the original query** with `EXPLAIN (ANALYZE, BUFFERS)`: without indexes, then with B+ tree, hash, BRIN and mixed indexes on the columns it filters and joins on.
3. **Rewrite the query** so the planner can do less work (for example `IN` → `EXISTS`, `> ALL` → `> MAX`, nested subqueries → joins) and analyse it again under the same five index setups.
4. **Compare** the 10 plans and execution times, and explain which index helps and why.

The full write-up, with all 120 query plans, is the [105-page report](docs/Report.pdf).

## The data

| Database | Tables | Generated |
|---|---|---|
| `schema1` University | department, instructor, student, course, section, takes, … | 60 departments, 1,878 courses, 1,278 instructors, 67,311 students, 100,000 enrolments |
| `schema2` Company | employee, department, project, works_on, dependent, … | 16,000 employees, 150 departments, 9,200 projects, 2,750 dependents |
| `schema3` Sailors | sailors, boat, reserves | 19,000 sailors, 3,000 boats, 35,000 reservations |
| `schema4` Movies | movie, actor, director, movie_cast, rating, … | 100,000 movies, 120,000 actors, 6,000 directors, 758,512 cast roles |

The generators in [`population/`](population) don't just insert random rows: they plant the values each query looks for (the MET department, boat 103, red and green boats, *Toy Story*, *Titanic*, Quentin Tarantino) so that every query returns between 45 and 33,393 rows.

## The 12 queries

| Query | Finds | Rewrite | Best result in the report |
|:---:|---|---|---|
| [1-A](queries/1A.sql) | MET students and the semester-5 2025 sections they took (full outer join) | Explicit column list | Mixed indexes, 23.4 ms |
| [2-A](queries/2A.sql) | Projects managed by or worked on by employee1 | `IN` → `EXISTS` | BRIN, 2.19 ms (original: 8.29 ms) |
| [2-B](queries/2B.sql) | Employees earning more than everyone in department 5 | `> ALL (…)` → `> (SELECT MAX …)` | Mixed (B+ tree on salary, hash on dno), **0.11 ms** (original: 16.6 ms) |
| [2-C](queries/2C.sql) | Employees with a dependent of the same first name and sex | `IN` → correlated `EXISTS` | B+ tree, 1.08 ms (original: 2.30 ms) |
| [2-D](queries/2D.sql) | Employees who have dependents | `EXISTS (SELECT *)` → `EXISTS (SELECT 1)` | BRIN, 0.80 ms (original: 1.54 ms) |
| [2-E](queries/2E.sql) | Employees earning over 40,000 in each department with more than 5 employees | Subquery → `JOIN … HAVING` | Mixed indexes, 4.91 ms |
| [3-A](queries/3A.sql) | Sailors who reserved boat 103 | `IN` → `JOIN` | B+ tree, 2.48 ms (original: 16.5 ms) |
| [3-B](queries/3B.sql) | Sailors who reserved a red boat | Nested `IN` → one `EXISTS` | Mixed indexes, 7.66 ms |
| [3-C](queries/3C.sql) | Sailors who reserved a red and a green boat | `IN` → correlated `EXISTS` | Hash, 13.97 ms |
| [4-A](queries/4A.sql) | Actors in *Toy Story* | Nested `IN` → `JOIN` | Mixed indexes, 78.2 ms (original: 139 ms) |
| [4-B](queries/4B.sql) | Directors of movies that share a role with *Titanic* | 4 levels of `IN` → nested `EXISTS` | B+ tree on the movie title, 578 ms |
| [4-C](queries/4C.sql) | Movies directed by Quentin Tarantino | Nested `IN` → two `JOIN`s | B+ tree, 0.85 ms |

Some general results from the analysis:

- **B+ trees** were the most reliable choice for joins and range conditions such as `salary > 40000`.
- **Hash indexes** only help equality conditions (`bid = 103`, `color = 'red'`).
- **BRIN indexes** are tiny but only pay off when the column follows the physical order of the table.
- **The rewrite mattered more than the index** for queries like 2-B: with `> ALL`, every employee's salary is checked against the whole list of department-5 salaries, while `> MAX(…)` needs one value, which a B+ tree on salary finds almost instantly.

## Tested on every push

GitHub Actions rebuilds everything from scratch on a PostgreSQL 16 server:

1. Creates the four databases with [`setup/create_db_tables.sql`](setup/create_db_tables.sql).
2. Compiles and runs the four Java generators.
3. Checks the data against the project requirements with [`tests/check_population.sql`](tests/check_population.sql), for example 60 departments with 20–45 courses each and at least 1,100 students each.
4. Runs the original and the optimized version of all 12 queries with [`tests/compare_queries.py`](tests/compare_queries.py), and checks that every pair returns exactly the same rows.

```
Query     Rows  Result
1A       33393  same result
2A        9200  same result
2B          45  same result
...
4C         516  same result
All 12 optimized queries return the same result as the original queries.
```

## Run it

You need PostgreSQL, a JDK and the [PostgreSQL JDBC driver](https://jdbc.postgresql.org/download/).

```console
$ psql -U postgres -f setup/create_db_tables.sql
$ javac -d build -cp postgresql.jar population/*.java
$ java -cp build:postgresql.jar Schema1        # then Schema2, Schema3, Schema4
$ python3 tests/compare_queries.py
```

The generators connect to `localhost:5432` as `postgres` by default. Set `PGHOST`, `PGPORT`, `PGUSER` and `PGPASSWORD` to change that. Schema 4 is the largest and takes 15 to 20 minutes to generate.

## Repository layout

| Folder | Contents |
|---|---|
| [`queries/`](queries) | The 12 queries, each with its original and optimized version |
| [`population/`](population) | Java data generators, one per database |
| [`worksheets/`](worksheets) | The SQL worksheets used during the analysis: `EXPLAIN` runs and the index sets that were created and dropped |
| [`docs/`](docs) | The [report](docs/Report.pdf) and the [project description](docs/project-description.pdf) |

## After the submission

The first commit holds the project files from June 2025, and [`docs/Report.pdf`](docs/Report.pdf) is the final report as it was submitted. A later review made a few changes:

- `Schema4.java` was submitted with every step except the ratings commented out (the steps had been run one at a time), so on its own it failed. All steps run again now.
- The connection settings can be set from the environment, and the Eclipse workspace and compiled files were removed from the repository.
- The query pairs in [`queries/`](queries) are taken from the worksheets, the versions that were actually run. In the report, the optimized 2-E query has two typos and the optimized 4-C query is missing the last-name filter.

---

## Team & course

Built for **Databases II (CSEN 604 / CSEN B504)** at the German International University in Berlin, Spring 2025 (Prof. Dr. Türker Ince), during a semester abroad from the German University in Cairo.

**Team 9:** Daniel Ehab · Omar Medhat Ahmed · Yahia Sameh Radi · Mina Hossam Samir
