#!/usr/bin/env bash

LOGFILE=/vagrant/validate_load.log

DT="$(date)"
echo "Running data validation script  $DT" >> $LOGFILE

ROW_COUNTS=$1

ERRORS=0

while read LINE
do
    echo "$LINE"

    EXPECTED_ROWS="$(echo "$LINE" | cut -d ' ' -f 1)"
    TABLE_NAME=$(echo "$LINE" | cut -d ' ' -f 2)

    # Start log string
    LOG="$TABLE_NAME  Expecting $EXPECTED_ROWS rows."

    LOADED=$(psql mimic -tc "SELECT COUNT(*) FROM $TABLE_NAME;")
    sleep 3  # Prevent too many accesses in sequence

    LOG="$LOG  $LOADED found."

    if [ $LOADED -ne $EXPECTED_ROWS ]
    then
        ERRORS=1
        LOG="$LOG  ** ERRORS FOUND. **"
    fi

    echo "$LOG" >> $LOGFILE

done < $ROW_COUNTS

if [ $ERRORS -eq 1 ]
then
    DT="$(date)"
    echo "Row count(s) incorrect, exiting with non-zero status  $DT" >> $LOGFILE
    exit 1
fi

DT="$(date)"
echo "Data validation complete  $DT" >> $LOGFILE

