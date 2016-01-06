jobsrunning=0
maxjobs=4

for ITEM in ADMISSIONS \
            CALLOUT \
            CAREGIVERS \
            CHARTEVENTS \
            CPTEVENTS \
            DATETIMEEVENTS \
            DIAGNOSES_ICD \
            DRGCODES \
            D_CPT \
            D_ICD_DIAGNOSES \
            D_ICD_PROCEDURES \
            D_ITEMS \
            D_LABITEMS \
            ICUSTAYS \
            INPUTEVENTS_CV \
            INPUTEVENTS_MV \
            LABEVENTS \
            MICROBIOLOGYEVENTS \
            NOTEEVENTS \
            OUTPUTEVENTS \
            PATIENTS \
            PRESCRIPTIONS \
            PROCEDUREEVENTS_MV \
            PROCEDURES_ICD \
            SERVICES \
            TRANSFERS
do
    if [ $jobsrunning -eq $maxjobs ]; then
        jobsrunning=0
        wait
    fi
    jobsrunning=$(( $jobsrunning+1))
    (
    TAR_DIR=/home/vagrant/src/physionet/mimic-iii/tarballs
    DEST=$TAR_DIR/$ITEM.tar.gz 
    BASE_URL=https://physionet.org/works/MIMICIIIClinicalDatabase/files
    URL=$BASE_URL/version_1_3/$ITEM.csv.gz
    wget --user $1 --password $2 --continue --no-check-certificate -O $DEST $URL
    ) &
done
