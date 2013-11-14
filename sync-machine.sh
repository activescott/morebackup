#!/bin/bash

##########
# Basic script for performing a time-machine-like backup via rsync. 
# Basically copies data into a directory with a date/time stamp in it.
# There is always a Latest symlink to the time stampped directory containing the most recent backup.
# Each new backup uses symlinks to the prior backup directory so that any files that were not changed since the most recent backup are not re-copied.
##########
show_help() {
	echo "Usage: sync-machine.sh [OPTIONS] SRC [DEST]"
	echo "SRC: A source path/host specifier that is compatible with the rsync command's SRC argument." 
	echo "     SRC could be a local path or a remote SSH path like user@host:/path/to/something or an rsync protocol like rsync://[USER@]HOST[:PORT]/path ."
	echo "DEST: A destination location for the files to be copied to. If DEST is not specified, it is assumed to be the current folder."
	echo "OPTIONS: "
	echo "    -d     Dry run; Performs a trial backup without making any changes."
	echo "    -h     Displays this help message."
	echo "    -v     Verbose output during transfer (every file listed)."
}

die () {
	show_help
    echo >&2 "$@"
    exit 1
}

########## Functions & Aliases ##########
##### These provide some indented logging with timestamps #####
LOGNESTING=0
log() {
	for (( c=0; c < $LOGNESTING; c++ ))
	do
		printf '  '
	done
	timestamptemp=`date "+%m/%d/%y %H:%M:%S"`
	echo $timestamptemp $1
}
logbegin() {
	log "$1"
	let LOGNESTING++
}
logend(){
	let LOGNESTING--
	log "$1"
}
########## /Functions & Aliases ##########


##### PARSE ARGUMENTS #####
unset IS_DRY_RUN
unset IS_VERBOSE
while getopts "dvh?" opt; do
	case "$opt" in
	h|\?)
    	show_help
		exit 0
		;;
	d)
		IS_DRY_RUN=1
		;;
	v)
		IS_VERBOSE=1
		;;
	esac
done
# Make sure that $1 begins at the first non-OPTIONS argument (i.e. SRC).
shift $((OPTIND-1))
# if the first non-OPTIONS argument is -- skip it (why would this happen again?).
[ "$1" = "--" ] && shift

[ $1 ] || die 'SOURCE was not specified!'
[ $2 ] || die 'DEST was not specified!'


exit 0;
##### /PARSE ARGUMENTS #####

DATE=`date "+%Y-%m-%dT%H_%M_%S"`
##### DEST #####
if [ $2 ]; then
	DESTROOT=$2
else
	DESTROOT=./
fi
# create DESTROOT if it doesn't exist (this part works fine with relative paths)
[ -d $DESTROOT ] || mkdir -pv $DESTROOT
# NOTE: ln & rsync seem to require a fully qualified path, relative path won't work. This is a trick to get qulified path:
DESTROOT_QUALIFIED=$(cd $DESTROOT; pwd);
log "Expanded \"$DESTROOT\" to \"$DESTROOT_QUALIFIED\"."
DESTROOT=$DESTROOT_QUALIFIED
DEST=$DESTROOT/$DATE

##### /DEST #####

#####
# NOTE: 
#	You can have multiple source directories separated by spaces.
# 	You cannot change case of the input or it will cause rsync to treat directories as different (e.g. /scott and /Scott) and do a full backup 
SRC=$1
#####

logbegin "\n**************************************************\nBackup begining at `date`..."

##### RSYNC OPTIONS #####
#NOTE: two v options (-vv) shows detailed exclude/include information.
# -C (cvs exclude) excludes dumb things but also USEFUL things like .exe files! So don't use that!
# -E (extended attributes) is necessary on macs to make things like packages work and special folders - and I'm sure other things that I don't know about).

# --stats provides a nice summary at the end without listing every file like -v or -vv
OPTIONS='-aExh --stats --delete --delete-excluded --exclude "*.sparsebundle/"'
# link-dest is the key to make sure backups are fast and effecieint with space. However, rsync spits an error message out (although it continues succesfully) if it doesn't exist. Lets prevent the error message:
if [ -d $DESTROOT/Latest ]; then
	OPTIONS="--link-dest $DESTROOT/Latest $OPTIONS"
fi

# --dry-run is handy for testing!
if [ ! -z "$IS_DRY_RUN" ]; then # not zero length?
	OPTIONS="--dry-run $OPTIONS"
fi

if [ ! -z "$IS_VERBOSE" ]; then
	OPTIONS="$OPTIONS -v"
fi
#####

##### RUN RSYNC #####
logbegin "Running rsync with options \"$OPTIONS\" source=\"$SRC\" destination=\"$DEST\"..."

rsync $OPTIONS \
$SRC \
$DEST.inprogress/

logend "Running rsync complete at `date`."
##### /RUN RSYNC #####

##### CLEANUP #####
# Note: it is important do only do the follow stuff if everything succeeds (i.e. directories exist), otherwise it can screw up future backups since they depend on the 'Latest' link being accurate.
log "Removing inprogress postifx"
if [ -d "$DEST.inprogress" ]; then
	mv $DEST.inprogress $DEST
else
	log "$DEST.inprogress didn't exist, so not removing .inprogress postfix."
fi

log "updating latest link"
if [ -d "$DEST" ]; then
	rm -f $DESTROOT/Latest
	ln -s $DEST $DESTROOT/Latest
else
	log "Latest link not updated since directory '$DEST' does not exist!"
fi
##### /CLEANUP #####

##### Diagnostic Output ##### 
logbegin "Displaying file counts for recent backups for comparison (this can help detect errors in backup if recent file counts vary widely):"
for D in `find -HL $DESTROOT -newerct '2 weeks ago' -maxdepth 1`; do echo $D: `find -HL $D | wc -l`; done
logend "Displaying file counts complete."
##### /Diagnostic Output ##### 

logend "Backup complete at: $DEST"