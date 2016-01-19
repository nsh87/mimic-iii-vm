LOGFILE=/vagrant/download_mimic.log

DT="$(date)"
echo "Running download script  $DT" >> $LOGFILE

for ITEM in ADMISSIONS CALLOUT CAREGIVERS CHARTEVENTS CPTEVENTS DATETIMEEVENTS DIAGNOSES_ICD DRGCODES D_CPT D_ICD_DIAGNOSES D_ICD_PROCEDURES D_ITEMS D_LABITEMS ICUSTAYS INPUTEVENTS_CV INPUTEVENTS_MV LABEVENTS MICROBIOLOGYEVENTS NOTEEVENTS OUTPUTEVENTS PATIENTS PRESCRIPTIONS PROCEDUREEVENTS_MV PROCEDURES_ICD SERVICES TRANSFERS
do
    TAR_DIR=/home/vagrant/src/physionet/mimic-iii/tarballs
    DEST=$TAR_DIR/$ITEM.csv.gz 
    BASE_URL=https://physionet.org/works/MIMICIIIClinicalDatabase/files
    URL=$BASE_URL/version_1_3/$ITEM.csv.gz

    # Start creating log string
    LOG="$DEST"

    # If ITEM exists, get checksum and don't re-download it if checksum is valid
    if [ -e $DEST ]
    then
        CHECKSUM="$(md5sum $DEST | cut -d ' ' -f 1)"
        LOG="$LOG  File exists, validating its checksum $CHECKSUM."
        if ! grep -wq "$CHECKSUM" $TAR_DIR/../zipped_file_checksums.txt
        then
            LOG="$LOG  Checksum not valid, re-downloading."
            rm $DEST
            wget --user $1 --password $2 --continue --no-check-certificate -O $DEST $URL
        else
            LOG="$LOG  Checksum valid, skipping this download."
        fi
    else
        LOG="$LOG  File does not exist, downloading."
        wget --user $1 --password $2 --continue --no-check-certificate -O $DEST $URL
    fi

    echo "$LOG" >> $LOGFILE
done

DT="$(date)"
echo "Downloads complete  $DT" >> $LOGFILE
