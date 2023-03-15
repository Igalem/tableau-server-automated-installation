# Check Tableau backup files location
tsm configuration get -k basefilepath.backuprestore

# Change Tableau backup files location
sudo mkdir -p /tableau/backup
sudo chown tableau:tableau /tableau/backupbackup

tsm configuration set -k basefilepath.backuprestore -v "/tableau/backup"

tsm pending-changes apply --ignore-prompt	

# Backup Server command [-d = Add date]
tsm maintenance backup -f tableau_server_backup_ -d --skip-compression --request-timeout 60000 --pg-only --ignore-prompt