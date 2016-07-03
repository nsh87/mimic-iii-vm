LOGFILE=/vagrant/extract_mimic.log

DT="$(date)"
echo "Running extraction script  $DT" >> $LOGFILE

TAR_DIR=$1
UNZIP_DIR=$2

echo "Removing orphaned CHARTEVENTSxx.csv files" >> $LOGFILE

# Remove any orphaned split-files from the large CHARTEVENTS.csv. This will
# allow creating new clean splits of CHARTEVENTS.csv when that is extracted.
find $UNZIP_DIR -maxdepth 1 -type f -regextype sed -regex '.*/CHARTEVENTS[0-9]\{2\}.*' -exec rm -f {} \;
find /home/vagrant -maxdepth 1 -type f -regextype sed -regex '.*/CHARTEVENTS[0-9]\{2\}.*' -exec rm -f {} \;

echo "Ensuring all files have been downloaded" >> $LOGFILE

# Ensure you have the correct number of downloaded files
NUM_FILES="$(ls -q $TAR_DIR | wc -l)"
if [ "$NUM_FILES" != "26" ]
then
    echo "Incorrect number of files ($NUM_FILES), aborting" >> $LOGFILE
    exit 1
fi

echo "Validating all downloaded file checksums" >> $LOGFILE

# Ensure downloaded file checksums are all valid
for F in $TAR_DIR/*.csv.gz
do
    CHECKSUM="$(md5sum $F | cut -d ' ' -f 1)"
    if ! grep -wq "$CHECKSUM" $TAR_DIR/../zipped_file_checksums.txt
    then
        echo "Checksum of $F invalid, aborting" >> $LOGFILE
        exit 1
    fi
done

for F in $TAR_DIR/*.csv.gz
do
    # Start creating log string
    LOG="$F"

    UNZIP_NAME="$(basename $F | sed s/.gz//)"
    DEST=$UNZIP_DIR/$UNZIP_NAME
    # If unzipped file exists, get checksum and don't unzip if checksum is valid
    if [ -e $DEST ]
    then
        # Extracted file exists, check checksum
        CHECKSUM="$(md5sum $DEST | cut -d ' ' -f 1)"
        LOG="$LOG  Extracted file exists, validating its checksum $CHECKSUM."
        if ! grep -wq "$CHECKSUM" $TAR_DIR/../unzipped_file_checksums.txt
        then
            # Checksum is invalid, remove existing file and re-extract
            LOG="$LOG  Checksum not valid, re-extracting."
            rm $DEST
            gzip -d -c $F > $DEST
        fi
    else
        # Extracted file doesn't exist. Check if it's the CHARTEVENTS file -
        # that will never exists since you split it into multiple files upon
        # extraction.
        if [ "$UNZIP_NAME" = "CHARTEVENTS.csv" ]
        then
            LOG="$LOG  Extracting into small files."
            # It's the CHARTEVENTS.csv.gz file. Extract it into several small
            # files.
            BASENAME="$(basename $F | sed s/.csv.gz//)"
            gzip -d -c $F | split -d -l 26000000 - $BASENAME
            LOG="$LOG  Extraction complete.  Adding CSV headers to split files."
            # Append .csv to the split files and move them to the unzip dir
            for SPLIT_CHARTEVENT_FILE in `ls -r /home/vagrant/$BASENAME*`
            do
                NEW_BASENAME="$(basename $SPLIT_CHARTEVENT_FILE)"
                # If it's not the first file, add the headers to the file
                FIRST_SPLIT_NAME=$BASENAME"00"
                if [ "$NEW_BASENAME" != "$FIRST_SPLIT_NAME" ]
                then
                    # Add headers from first file to all other file
                    HEADERS=$(head -n 1 /home/vagrant/$FIRST_SPLIT_NAME)
                    sed -e "1i\\$HEADERS" $SPLIT_CHARTEVENT_FILE > $UNZIP_DIR/$NEW_BASENAME.csv
                    rm -f $SPLIT_CHARTEVENT_FILE
                else
                    mv $SPLIT_CHARTEVENT_FILE $UNZIP_DIR/$NEW_BASENAME.csv
                fi
            done
        else
            # It's all other files, just uncompress it
            LOG="$LOG  Extracted file does not exist, extracting."
            gzip -d -c $F > $DEST
        fi
    fi

    echo "$LOG" >> $LOGFILE
done

DT="$(date)"
echo "Extractions complete  $DT" >> $LOGFILE
