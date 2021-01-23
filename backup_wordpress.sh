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
database_name=""
database_user=""
database_pass=""

while getopts ":m:t:d:u:p:" opt; do
  case $opt in
    m)
      wordpress_path="$OPTARG"
      ;;
    t)
      backup_target="$OPTARG"
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

initialize() {
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

backup_database() {
    echo "$(date) - Dumping Database"
    ${exe_mysqldump} ${opts_mysqldump} "${database_name}" -u"${database_user}" -p"${database_pass}" > "${backup_target}/wordpress_db_backup.sql"
}

backup_files() {
    echo "$(date) - Backup Files"
    ${exe_rsync} ${opts_rsync} "${wordpress_path}/" "${backup_target}/files/"
}

finish () {
    echo "$(date) - Compress Backup"
    ${exe_tar} ${opts_tar} "${backup_target}.tar.gz" "${backup_target}"
    echo "$(date) - All Done"
}

# Main:
initialize 2>&1|tee -a $logfile
backup_database 2>&1|tee -a $logfile
backup_app 2>&1|tee -a $logfile
backup_data 2>&1|tee -a $logfile
finish 2>&1|tee -a $logfile
