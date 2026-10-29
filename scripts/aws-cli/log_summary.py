#!/usr/bin/env python3
"""
log_summary.py - count log lines by severity

Python port of log-summary.sh. Same job, same exit codes.

Usage:
    python log_summary.py <path-to-logfile>

Exit codes:
    0  summary produced, no errors in log
    1  summary produced, but the log contains ERROR lines
    2  bad input (no argument, too many arguments, file missing/unreadable)
"""

import sys
import os


def main():
    # ---------- 1. validate arguments ----------
    # TODO: check that exactly ONE argument was given.
    #       Python: len(sys.argv) is 1 when no args, 2 when one arg.
    #       If wrong: print a usage line to stderr, then sys.exit(2)
    #
    #   hint:  print("usage: ...", file=sys.stderr)
    #
    # YOUR CODE HERE
    if len(sys.argv) != 2 :
     print("usage: python log_summary.py <logfile>", file = sys.stderr)
     sys.exit(2)


    logfile = sys.argv[1]

    # ---------- 2. validate the file ----------
    # TODO: check the file exists AND is readable.
    #       Python: os.path.isfile(logfile) and os.access(logfile, os.R_OK)
    #       If not: print an error to stderr, then sys.exit(2)
    #
    # YOUR CODE HERE
    if not os.path.isfile(logfile) or not os.access(logfile, os.R_OK) :
       print(f"Error: {logfile} is missing or not readable", file=sys.stderr)
       sys.exit(2)


    # ---------- 3. read the file ----------
    # TODO: read all lines into a list called `lines`.
    #       Python: with open(logfile) as f:  lines = f.read().splitlines()
    #
    # YOUR CODE HERE
    with open(logfile) as f:
        lines = f.read().splitlines()



    # ---------- 4. count ----------
    # TODO: total = number of lines
    #       errors = number of lines containing "ERROR"
    #       warns  = number of lines containing "WARN"
    #       infos  = number of lines containing "INFO"
    #
    #   hint: sum(1 for l in lines if "ERROR" in l)
    #   OR use Counter, like the test you just ran.
    #
    # YOUR CODE HERE
    total = len(lines)
    errors = sum(1 for l in lines if "ERROR" in l)
    warns = sum(1 for l in lines if "WARN" in l)
    infos = sum(1 for l in lines if "INFO" in l)



    # ---------- 5. print the summary ----------
    # TODO: print this shape (note the column alignment):
    #
    #   === LOG SUMMARY: testdata/app.log ===
    #     total  : 7
    #     ERROR  : 2
    #     WARN   : 1
    #     INFO   : 4
    #
    # YOUR CODE HERE
    print(f"=== LOG SUMMARY: {logfile} ===")
    print(f"  total  : {total}")
    print(f"  ERROR  : {errors}")
    print(f"  WARN   : {warns}")
    print(f"  INFO   : {infos}")
    


    # ---------- 6. exit with the right code ----------
    # TODO: if errors > 0 -> sys.exit(1)
    #       otherwise     -> sys.exit(0)
    #
    # YOUR CODE HERE
    if errors > 0:
       sys.exit(1)
    else:
       sys.exit(0)


if __name__ == "__main__":
    main()
