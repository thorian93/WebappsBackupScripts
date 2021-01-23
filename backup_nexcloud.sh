#!/usr/bin/env bash
#
# Written by: Robin Gierse - info@thorian93.de - on 20210123
#
# Purpose:
# This script backs up a nextcloud instance.
#
# Version: 0.1 on 20210123
#
# Reference: https://docs.nextcloud.com/server/latest/admin_manual/maintenance/backup.html
#
# Usage:
# ./backup_nextcloud.sh

set -e

# Variables:
nextcloud_path="/var/www/nextcloud"
nextcloud_data_path="/var/www/nextcloud/data"
backup_files="false"
backup_target="/tmp/nextcloud_backup"
logfile="/tmp/nextcloud_backup.log"
exe_rsync="$(command -v rsync)"
opts_rsync="-Aavx"
exe_tar="$(command -v tar)"
opts_tar="-caf"
exe_mysqldump="$(command -v mysqldump)"
opts_mysqldump="--single-transaction"
database_name=""
database_user=""
database_pass=""
webserver_user="www-data"

while getopts ":m:t:d:u:p:f" opt; do
  case $opt in
    m)
      nextcloud_path="$OPTARG"
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
    f)
      backup_files="true"
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
    if [ ! -d ${nextcloud_path} ]
    then
        echo 'No nextcloud Installation found!' ; exit 1
    fi
    if [ -z "${database_name}" ]
    then
        echo 'No nextcloud Database specified!' ; exit 1
    fi
    echo "$(date) - Ready to take off"
	echo "$(date) - Enabling Maintenance Mode"
	sudo -u "${webserver_user}" php "${nextcloud_path}/occ" maintenance:mode --on
}

backup_database() {
    echo "$(date) - Dumping Database"
    ${exe_mysqldump} ${opts_mysqldump} "${database_name}" -u"${database_user}" -p"${database_pass}" > "${backup_target}/nextcloud_db_backup.sql"
}

backup_app() {
    echo "$(date) - Backup App"
    ${exe_rsync} ${opts_rsync} --exclude="${nextcloud_data_path}"  "${nextcloud_path}/" "${backup_target}/app/"
}

backup_files() {
    echo "$(date) - Backup Data"
    ${exe_rsync} ${opts_rsync} "${nextcloud_data_path}" "${backup_target}/data"
}

finish () {
  echo "$(date) - Compress Backup"
  ${exe_tar} ${opts_tar} "${backup_target}.tar.gz" "${backup_target}"
	echo "$(date) - Disabling Maintenance Mode"
	sudo -u "${webserver_user}" php "${nextcloud_path}/occ" maintenance:mode --off
  echo "$(date) - All Done"
}

# Main:
initialize 2>&1|tee -a $logfile
backup_database 2>&1|tee -a $logfile
backup_app 2>&1|tee -a $logfile
if [ "${backup_files}" == "true" ]
then
  backup_files 2>&1|tee -a $logfile
fi
finish 2>&1|tee -a $logfile
