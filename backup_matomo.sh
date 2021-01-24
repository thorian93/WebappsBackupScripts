#!/usr/bin/env bash
#
# Written by: Robin Gierse - info@thorian93.de - on 20210123
#
# Purpose:
# This script backs up a matomo instance.
#
# Version: 0.1 on 20210123
#
# Reference: https://matomo.org/faq/how-to-install/faq_138/
#
# Usage:
# ./backup_matomo.sh

# Variables:
matomo_path="/var/www/matomo"
backup_target="/tmp/matomo_backup"
logfile="/tmp/matomo_backup.log"
exe_rsync="$(command -v rsync)"
opts_rsync="-avzh"
exe_tar="$(command -v tar)"
opts_tar="-caf"
exe_mysqldump="$(command -v mysqldump)"
opts_mysqldump="--extended-insert --no-autocommit --quick --single-transaction"
database_name=""
database_user=""
database_pass=""

while getopts ":s:t:d:u:p:h" opt; do
  case $opt in
    s)
      matomo_path="$OPTARG"
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
    if [ ! -d "${matomo_path}" ]
    then
        echo 'No Matomo Installation found!' ; exit 1
    fi
    if [ -z "${database_name}" ]
    then
        echo 'No Matomo Database specified!' ; exit 1
    fi
    echo "$(date) - Ready to take off"
}

_backup_database() {
    echo "$(date) - Dumping Database"
    ${exe_mysqldump} ${opts_mysqldump} "${database_name}" -u"${database_user}" -p"${database_pass}" > "${backup_target}/matomo_db_backup.sql"
}

_backup_config() {
    echo "$(date) - Backup Config"
    ${exe_rsync} ${opts_rsync} "${matomo_path}/config/config.ini.php" "${backup_target}/config.ini.php"
}

_backup_plugins() {
    echo "$(date) - Backup Plugins"
    ${exe_rsync} ${opts_rsync} "${matomo_path}/plugins" "${backup_target}/"
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
_backup_config 2>&1|tee -a $logfile
_backup_plugins 2>&1|tee -a $logfile
_finish 2>&1|tee -a $logfile
