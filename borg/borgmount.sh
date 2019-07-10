#!/bin/bash

##################################
# Borg mount script for Hetzner  #
# by David Horvath               #
# dacr@dacr.hu                   #
##################################

if [ -z "$1" ] ; then
    echo ""
    echo "###########################################"
    echo "restore.sh [list|list backupname|mount backupname targetfolder|umount targetfolder]"
    echo ""
    echo "Examples:"
    echo "restore.sh list"
    echo "restore.sh list 2018-10-12_02:25"
    echo "restore.sh mount 2018-10-12_02:25 /var/tmp/bkp"
    echo "restore.sh umount /var/tmp/bkp"
    echo "###########################################"
    echo ""
    exit
fi

################### CONFIG ###################
STORAGEBOX_USER="u987654321"
STORAGEBOX_HOST="u987654321.your-storagebox.de"
SSH_KEY="/root/.ssh/borg"
BORG_PASSPHRASE=""
REPOS_FOLDER="borgbackup"
##############################################


# SET VARIABLES
export BORG_RSH="ssh -oStrictHostKeyChecking=no -i $SSH_KEY"
export BORG_PASSPHRASE

# set REPO
REPO=$(hostname)

if [ "$1" = "list" ] ; then
    if [ -n "$2" ] ; then
        /usr/bin/borg list ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO::$2
        exit
    fi
    /usr/bin/borg list ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO
fi

if [ "$1" = "mount" ] ; then
    /usr/bin/borg mount ssh://$STORAGEBOX_USER@$STORAGEBOX_HOST:23/./$REPOS_FOLDER/$REPO::$2 $3
fi

if [ "$1" = "umount" ] ; then
    /usr/bin/borg umount $2
fi
