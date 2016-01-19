LOGFILE=/vagrant/load_data.log

DT="$(date)"
echo "Running data loader  $DT" >> $LOGFILE

DATA_DIR=$1

# Load all tables except CHARTEVENTS first, so you can free up space
for F in `find /home/vagrant/src/physionet/mimic-iii/unzipped -maxdepth 1 -type f -not -name '*CHARTEVENTS*' | xargs ls -Sr`
do
    # Start creating log string
    LOG="$F"

    BASENAME="$(basename $F | sed s/.csv//)"
    TABLE_NAME=$BASENAME

    LOG="$LOG  Loading $BASENAME.csv into table $TABLE_NAME."

    CMD="copy $TABLE_NAME FROM '$F' DELIMITER ',' CSV HEADER;"
    psql mimic -c "$CMD" 2>> $LOGFILE

    echo "$LOG  Deleting loaded CSV file."
    rm $F

    echo "$LOG" >> $LOGFILE
done

unset F

# Load the CHARTEVENTS table
for F in `find /home/vagrant/src/physionet/mimic-iii/unzipped -maxdepth 1 -type f -name '*CHARTEVENTS*' | sort`
do
    # Start creating log string
    LOG="$F"

    BASENAME="$(basename $F | sed s/.csv//)"
    TABLE_NAME="CHARTEVENTS"

    LOG="$LOG  Loading $BASENAME.csv into table $TABLE_NAME."

    CMD="copy $TABLE_NAME FROM '$F' DELIMITER ',' CSV HEADER;"
    psql mimic -c "$CMD" 2>> $LOGFILE
    sleep 5  # Prevent too many accesses in sequence

    echo "$LOG  Deleting loaded CSV file."
    rm $F

    echo "$LOG" >> $LOGFILE
done
    
DT="$(date)"
echo "Data load complete  $DT" >> $LOGFILE
