morebackup
===========
Handy scripts for backups.

[Suggestions/issues](https://github.com/activescott/morebackup/issues) and pull requests are welcome!

sync-machine.sh
-----------
Uses strategy like Apple's Time Machine to perform incremental backups. It makes backups very fast and storage of them very small. Basically it works as follows:
* Each backup is basically a copy of the files from the source directory into a directory named with a date+time stamp.
* There is always a `Latest` directory symlinked to the time-stamped directory containing the most recent backup.
* Each new backup uses symlinks to the files & folders in the prior backup directory so that **any files that were not changed since the most recent backup are not stored again**, resulting in effecient storage.
* It uses an rsync for copying files which results in only copying things that have changed since the last backup.

Some notable features/benefits of this technique: 
- Each of the date+timestamp directories is exactly like the original source directory being backed up so you don't need any special tools to restore from backup. Just a standard file copy will do.
- The only thing it really relies on is rsync and bash script so it should be portable.
- SSH and rsync protocol is supported since rsync supports it.
- I love rsync, but sometimes it's hard to get the options just right. This scripts memorializes the best options I know of for backups.

### Examples

The below example would backup the `/Users/mranderson` directory to `/Volumes/MyExternalDrive/Backups`. Time-stamped directories like `2013-11-14T05_56_07` would be in the Backups folder for each of the backups (i.e. each time the sync-machine.sh script is run):

	sync-machine.sh /Users/mranderson /Volumes/MyExternalDrive/Backups

*Compatibility*: I've only used it on OSX, but it should work on linux and windows+cygwin with no or minor modifications. 


backup-mysql.sh
-----------
Uses SSH to create a local backup of a remote MySQL database. This is ideal for website hosts that host applications that have a database such as the various content management systems (joomla, wordpress, etc.).
