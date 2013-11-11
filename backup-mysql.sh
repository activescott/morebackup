#!/bin/bash
##########
# Script to backup the mysql DB on a remote server via ssh and then download the backed up file via scp.
# This script makes a lot of assumptions and may not be all that reuable. Maybe someday I'll clean it up.
##########


show_help () {
	echo "Usage: backup-mysql.sh -h HOST -u USERNAME -p MYSQL_PASSWORD DBNAME [DESTDIR]"
	echo " HOST           The hostname to SSH into to backup mysql."
	echo " USERNAME       The username to use on the SSH host and with the mysqldump command."
	echo " MYSQL_PASSWORD The password with the mysqldump command."
	echo " DBNAME         The name of the mysql database to backup."
	echo " DESTDIR        The local destination directory to receive the backup file (the file is named \"<TIMESTAMP>_mysqldump_<DBNAME>.sql\")."
	echo "                If not specified, sends backup stdout."
	echo ""
}

die () {
	show_help
	echo >&2 "$@"
	exit 1
}

##### PARSE ARGUMENTS #####
unset THEHOST
unset THEUSER
unset MYSQL_PASSWORD
unset DBNAME
unset DESTDIR
while getopts "?h:u:p:" opt; do
	#echo "getopts found $opt=$OPTARG"
	case "$opt" in
	\?)
    	show_help
		exit 0
		;;
	h)
		THEHOST=$OPTARG
		;;
	u)
		THEUSER=$OPTARG
		;;
	p)
		MYSQL_PASSWORD=$OPTARG
		;;
	esac
done

# Make sure that $1 begins at the first non-OPTIONS argument (i.e. SRC).
shift $((OPTIND-1))
# if the first non-OPTIONS argument is -- skip it (why would this happen again?).
[ "$1" = "--" ] && shift

DBNAME=$1
DESTDIR=$2

DATESTAMP=`date "+%Y-%m-%dT%H_%M_%S"`
BACKUPFILENAME="_mysqldump_$DBNAME.sql"
BACKUPFILENAME=$DATESTAMP$BACKUPFILENAME

# Display message to user with what we understood as arguments:
MSG="Backing up MySQL database '$DBNAME' from '$THEUSER@$THEHOST'"
[ -z $DESTDIR ] ||  MSG="$MSG to '$BACKUPFILENAME'"
echo "$MSG..."

[ $THEHOST ] || die 'HOST must be specified!'
[ $DBNAME ] || die 'DBNAME must be specified!'
[ $THEUSER ] || die 'USERNAME must be specified!'
[ $MYSQL_PASSWORD ] || die 'MYSQL_PASSWORD must be specified!'
##### /PARSE ARGUMENTS #####


echo -e "**********"
echo -e "Performing mysqldump backup via ssh...\n"
ssh $THEUSER@$THEHOST "mysqldump -u $THEUSER -p$MYSQL_PASSWORD $DBNAME" > $DESTDIR/$BACKUPFILENAME 
echo -e "Performing mysqldump backup via ssh COMPLETE."

echo -e "**********"
echo -e "First part of the backed up file is below:"
head -n 25 $DESTDIR/$BACKUPFILENAME 
echo -e "..."
echo -e "..."
echo -e "..."
echo -e "**********"