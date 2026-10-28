#!/usr/bin/env bash
#
# log-summary.sh — count log lines by severity
#
# Usage:
#   ./log-summary.sh <path-to-logfile>
#
# Exit codes:
#   0  summary produced, no errors in log
#   1  summary produced, but the log contains ERROR lines
#   2  bad input (no argument, too many arguments, file missing/unreadable)
#

set -uo pipefail

# ---------- 1. validate arguments ----------
# TODO: check that exactly ONE argument was given.
#       hint: $# is the argument count; use -ne 1
#       if not: print a usage line to stderr (>&2) and exit 2
#
# 
if [ $# -ne 1 ]; then
echo "Argument not equal to one" >&2
exit 2
fi


LOGFILE="$1"

# ---------- 2. validate the file ----------
# TODO: check that $LOGFILE exists and is a readable regular file.
#       hint: [ -f "$LOGFILE" ] and [ -r "$LOGFILE" ]
#       if not: print an error to stderr and exit 2
#
if [ ! -f "$LOGFILE" ] || [ ! -r "$LOGFILE" ]; then
echo "$LOGFILE does not exist and not readable" >&2
exit 2 
fi


# ---------- 3. count lines ----------
# TODO: count the TOTAL number of lines.
#       hint: wc -l < "$LOGFILE"
#
TOTAL=$(wc -l < "$LOGFILE")
ERRORS=$(grep -c "ERROR" "$LOGFILE")
WARNS=$(grep -c "WARN" "$LOGFILE")
INFOS=$(grep -c "INFO" "$LOGFILE")



# ---------- 4. print the summary ----------
# TODO: print something like:
#
#   === LOG SUMMARY: /tmp/logtest/app.log ===
#     total  : 7
#     ERROR  : 2
#     WARN   : 1
#     INFO   : 4
#
# YOUR CODE HERE
echo "=== LOG SUMMARY: $LOGFILE ==="
echo "  total  : $TOTAL"
echo "  ERROR  : $ERRORS"
echo "  WARN   : $WARNS"
echo "  INFO   : $INFOS"


# ---------- 5. exit with the right code ----------
# TODO: if ERROR count is greater than 0 -> exit 1
#       otherwise -> exit 0
#
# YOUR CODE HERE
if [ "$ERRORS" -gt 0 ]; then
    exit 1
fi
exit 0 
