TAR_DIR=$1
UNZIP_DIR=$2

for F in $TAR_DIR/*.csv.gz
do
    UNZIP_NAME="$(basename $F | sed s/.gz//)"
    DEST=$UNZIP_DIR/$UNZIP_NAME
    # If unzipped file exists, get checksum and don't unzip if checksum is valid
    if [ -e $DEST ]
    then
        CHECKSUM="$(md5sum $DEST | cut -d ' ' -f 1)"
        if ! grep -wq "$CHECKSUM" unzipped_file_checksums.txt
        then
            rm $DEST
            gzip -d -c $F > $DEST
        fi
    else
        gzip -d -c $F > $DEST
    fi
done
    
