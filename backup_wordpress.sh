#!/usr/bin/env bash
#
# Written by: Robin Gierse - info@thorian93.de - on 20210123
#
# Purpose:
# This script backs up a wordpress instance.
#
# Version: 0.1 on 20210123
#
# Reference: https://wordpress.org/support/article/wordpress-backups/
#
# Usage:
# ./backup_wordpress.sh

set -e

# Variables:
wordpress_path="/var/www/wordpress"
backup_target="/tmp/wordpress_backup"
logfile="/tmp/wordpress_backup.log"
exe_rsync="$(command -v rsync)"
opts_rsync="-avzh"
exe_tar="$(command -v tar)"
opts_tar="-caf"
exe_mysqldump="$(command -v mysqldump)"
opts_mysqldump="--add-drop-table"
database_name=''
database_host='localhost'
database_user=''
database_pass=''

while getopts ":s:t:d:u:p:h" opt; do
  case $opt in
    s)
      wordpress_path="${OPTARG%/}"
      ;;
    t)
      backup_target="${OPTARG%/}"
      ;;
    d)
      database_name="$OPTARG"
      ;;
    u)
      database_user="$OPTARG"
      ;;
    p)
      database_pass="$OPTARG"
      ;;
    h)
      print_help="true"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Functions:

_initialize() {
    if [ ! -d "${backup_target}" ]
    then
        echo "Creating backup target: ${backup_target}"
        mkdir -p "${backup_target}"
    fi
    if [ ! -d "${wordpress_path}" ]
    then
        echo 'No wordpress Installation found!' ; exit 1
    fi
    if [ -z "${database_name}" ]
    then
        echo 'No wordpress Database specified!' ; exit 1
    fi
    echo "$(date) - Ready to take off"
}

_backup_database() {
    echo "$(date) - Dump Database"
    ${exe_mysqldump} ${opts_mysqldump} "${database_name}" -h"${database_host}" -u"${database_user}" -p"${database_pass}" > "${backup_target}/wordpress_db_backup.sql"
}

_backup_files() {
    echo "$(date) - Backup Files"
    ${exe_rsync} ${opts_rsync} "${wordpress_path}/" "${backup_target}/files/"
}

_finish () {
    echo "$(date) - Compress Backup"
    ${exe_tar} ${opts_tar} "${backup_target}.tar.gz" "${backup_target}"
    echo "$(date) - All Done"
}

_help() {
    echo '#######################################################################################'
    echo '# -s    The source of the files. Referes to your webapp installation.                 #'
    echo '# -t    The target for the backup. Backup files will be created under this directory. #'
    echo '# -d    Database to backup.                                                           #'
    echo '# -u    Database user.                                                                #'
    echo '# -p    Database password.                                                            #'
    echo '# -h    Print this help message.                                                      #'
    echo '#######################################################################################'
}

# Main:
if [ "${print_help}" == "true" ]
then
  _help && exit 0
fi
_initialize 2>&1|tee -a $logfile
_backup_database 2>&1|tee -a $logfile
_backup_files 2>&1|tee -a $logfile
_finish 2>&1|tee -a $logfile
