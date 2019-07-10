#!/bin/bash

##################################
# Borg backup script for Hetzner #
# by David Horvath               #
# dacr@dacr.hu                   #
##################################

######################################################################
# You cat put this to crontab:
#######
# BKP #
#######
# 20 2 * * *       root    /usr/local/sbin/backup.sh  > /dev/null 2>&1
######################################################################

################### CONFIG ###################
MYSQL_DUMP="true"
MYSQL_DUMP_DIR="/var/www/SQL"
MYSQL_USER=""
MYSQL_PASS=""
MYSQL_HOST="localhost"
MONGO_DUMP="true"
MONGO_DUMP_DIR="/var/www/MONGO/"
STORAGEBOX_USER="u987654321"
STORAGEBOX_HOST="u987654321.your-storagebox.de"
SSH_KEY="/root/.ssh/borg"
BORG_PASSPHRASE=""
REPOS_FOLDER="borgbackup"
BACKUP_FOLDERS="/etc /home /var/www"
KEEP_BACKUP="30d"
LOG="/var/log/backup.log"
##############################################

# make log
exec > >(tee -i ${LOG})
exec 2>&1


# check gorg command
command -v borg

# install borg if not exist
if [ $? -ne 0 ] ; then

    # check OS
    . /etc/os-release

    case $ID in
    fedora)
    dnf -y install borgbackup
    ;;
    ubuntu)
    apt -y update
    apt -y install borgbackup
    ;;
    debian)
    apt -y update
    apt -y install borgbackup
    ;;
    centos)
    yum -y install borgbackup
    ;;
    esac
fi


# SET VARIABLES
export BORG_RSH="ssh -oStrictHostKeyChecking=no -i $SSH_KEY -oStrictHostKeyChecking=no"
export BORG_PASSPHRASE

# set REPO
REPO=$(hostname)

# make mysql dump if it enable
if [ $MYSQL_DUMP = "true" ] ; then
    # make mysql dump dir if it not exist
    if [ ! -d $MYSQL_DUMP_DIR ] ; then
	mkdir -p $MYSQL_DUMP_DIR
    fi
    DB=$(mysql -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS -e "show databases" | awk {'print $1'} | grep -vE "Database|information_schema|performance_schema")

    for i in $DB ; do
    if [ "${i}" = mysql ] ; then
        /usr/bin/mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS $i user | gzip > $MYSQL_DUMP_DIR/${i}.sql.gz
    else
        /usr/bin/mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASS $i | gzip  > $MYSQL_DUMP_DIR/${i}.sql.gz
    fi
    done
fi


# make mongo dump if it enable
if [ $MONGO_DUMP = "true" ] ; then
    # make mongo dump dir if it not exist
    if [ ! -d $MONGO_DUMP_DIR ] ; then
	mkdir -p $MONGO_DUMP_DIR
    fi
    mongodump -o $MONGO_DUMP_DIR
fi


# create dirs on storage box
sftp -oStrictHostKeyChecking=no -P23 -i $SSH_KEY $STORAGEBOX_USER@$STORAGEBOX_HOST <<EOF
    mkdir $REPOS_FOLDER
    mkdir $REPOS_FOLDER/$REPO
    exit
EOF

# init borg repository
/usr/bin/borg init --encryption=repokey ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO

# cleanup repository
/usr/bin/borg prune -v --list --keep-within=$KEEP_BACKUP ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO

# create backup
/usr/bin/borg create -v --stats -C zlib,9 ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO::'{now:%Y-%m-%d_%H:%M}' $BACKUP_FOLDERS
