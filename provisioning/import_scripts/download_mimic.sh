jobsrunning=0
maxjobs=4

for ITEM in ADMISSIONS CALLOUT CAREGIVERS CHARTEVENTS CPTEVENTS DATETIMEEVENTS DIAGNOSES_ICD DRGCODES D_CPT D_ICD_DIAGNOSES D_ICD_PROCEDURES D_ITEMS D_LABITEMS ICUSTAYS INPUTEVENTS_CV INPUTEVENTS_MV LABEVENTS MICROBIOLOGYEVENTS NOTEEVENTS OUTPUTEVENTS PATIENTS PRESCRIPTIONS PROCEDUREEVENTS_MV PROCEDURES_ICD SERVICES TRANSFERS
do
    if [ $jobsrunning -eq $maxjobs ]; then
        jobsrunning=0
        wait
    fi
    jobsrunning=$(( $jobsrunning+1))
    (
    TAR_DIR=/home/vagrant/src/physionet/mimic-iii/tarballs
    DEST=$TAR_DIR/$ITEM.csv.gz 
    BASE_URL=https://physionet.org/works/MIMICIIIClinicalDatabase/files
    URL=$BASE_URL/version_1_3/$ITEM.csv.gz
    # If ITEM exists, get checksum and don't re-download it if checksum is valid
    if [ -e $DEST ]
    then
        CHECKSUM="$(md5sum $DEST | cut -d ' ' -f 1)"
        if ! grep -wq "$CHECKSUM" zipped_file_checksums.txt
        then
            rm $DEST
            wget --user $1 --password $2 --continue --no-check-certificate -O $DEST $URL
        fi
    else
        wget --user $1 --password $2 --continue --no-check-certificate -O $DEST $URL
    fi
    ) &
done
