#!/usr/bin/env python3
"""Runs the original and the optimized version of every query in queries/ and checks
that they return the same rows (as a multiset, ignoring order).

Query 1-A is the exception: its optimized version lists 13 columns instead of SELECT *
over both sides of the join, so for it the (student id, section id) pairs are compared.

Connection settings come from the usual PGHOST, PGPORT, PGUSER and PGPASSWORD variables.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUERIES = os.path.join(ROOT, "queries")


def run(database, sql):
    result = subprocess.run(
        ["psql", "-X", "-q", "-A", "-t", "-F", "\t", "-v", "ON_ERROR_STOP=1", "-d", database],
        input=sql, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return [line for line in result.stdout.split("\n") if line != ""]


def split(path):
    text = open(path, encoding="utf-8").read()
    original, optimized = re.split(r"^-- Optimized.*$", text, maxsplit=1, flags=re.M)
    original = re.split(r"^-- Original\s*$", original, maxsplit=1, flags=re.M)[1]
    return original.strip(), optimized.strip()


def ids_1a_original(rows):
    # SELECT * columns: student (id, name, tot_credit, department, advisor_id), then takes
    # (student_id, section_id, grade), then section. The id is the student's, or the
    # taker's when no MET student matched.
    return sorted((c[0] or c[5], c[6]) for c in (r.split("\t") for r in rows))


def ids_1a_optimized(rows):
    # Columns: COALESCE(id, student_id), name, tot_credit, department, advisor_id, section_id, ...
    return sorted((c[0], c[5]) for c in (r.split("\t") for r in rows))


def main():
    failures = 0
    print(f"{'Query':<7}{'Rows':>7}  Result")
    for name in sorted(os.listdir(QUERIES)):
        query = name[:-4]
        database = "schema" + query[0]
        original, optimized = split(os.path.join(QUERIES, name))
        try:
            rows_a = run(database, original)
            rows_b = run(database, optimized)
            if not rows_a:
                raise AssertionError("the original query returned no rows")
            if query == "1A":
                # Original columns: student (5), takes (3), section (7); optimized: id first, section_id 6th.
                same = ids_1a_original(rows_a) == ids_1a_optimized(rows_b)
            else:
                same = sorted(rows_a) == sorted(rows_b)
            if not same:
                raise AssertionError(f"different results: {len(rows_a)} rows vs {len(rows_b)} rows")
            print(f"{query:<7}{len(rows_a):>7}  same result")
        except Exception as error:  # noqa: BLE001 - report every query
            failures += 1
            print(f"{query:<7}{'':>7}  FAILED: {error}")
    if failures:
        sys.exit(f"{failures} query pair(s) failed")
    print("All 12 optimized queries return the same result as the original queries.")


if __name__ == "__main__":
    main()
