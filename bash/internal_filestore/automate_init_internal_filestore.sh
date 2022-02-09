#!/bin/bash
# ----------------------------------------- Setting parameters:
HOSTNAME=$(hostname -i)
SMTP_URL="XXXX"
SMTP_MAIL="XXXX@XXXX"

# Tableau data device location
MOUNT_POINT=~

# Setup Tableau Server Version for install
TABLEAU_SERVER_VER='2021-4-2'
TS_VER_DIR="${TABLEAU_SERVER_VER//-/.}"
TS_VER_RMP="tableau-server-${TABLEAU_SERVER_VER}.x86_64.rpm"
TS_VER_RMP_LINK="https://downloads.tableau.com/esdalt/${TS_VER_DIR}/${TS_VER_RMP}"
PSGSQL_JAR='postgresql-42.2.22.jar'
PSGSQL_DIR='/opt/tableau/tableau_driver/jdbc'
CHD_HIVE_RPM='ClouderaHiveODBC-2.6.11.1011-1.x86_64.rpm'
CHD_IMPALA_RPM='ClouderaImpalaODBC-2.6.14.1016-1.x86_64.rpm'

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

genpass() { 
openssl rand -hex 10 
}

# TABLEAU application admin user 
ADMIN_USER='admin'
ADMIN_PWD=genpass

# TABLEAU Server managmanet admin user 
ADMIN_SERVER_USER='tableau'
ADMIN_SERVER_PWD=genpass

# ===  Starting envirounment installation ===
# --------------------------------------------
echo -e $YELLOW "===  Starting envirounment installation ===" $NORMAL
sudo yum -y update
sudo yum -y upgrade
sudo yum -y install htop

# The best way is to run that script after resource "aws_volume_attachment" created
sleep 60

# ===  Set local envirounment parameters ===
# ------------------------------------------

# [optional] - Backup /etc/environment
sudo cp /etc/environment /etc/environment.orid

# Edit /etc/environment - Adding  these lines into 
sudo bash -c 'echo -e "LANG=en_US.utf-8" >> /etc/environment'
sudo bash -c 'echo -e "LC_ALL=en_US.utf-8" >> /etc/environment'

# ---------------------------------------------------------------------------------------------------------------------

# Install ODBC driver manager
echo -e $YELLOW "=== Install ODBC driver manager ===" $NORMAL
sudo yum -y install libiodbc

# Install the unixODBC manager
sudo yum -y install unixODBC* unixODBC-devel*

# Install libsasl libraries 
echo -e $YELLOW "=== Install libsasl libraries  ===" $NORMAL
sudo yum -y groupinstall "Development Tools"
sudo yum -y install cyrus-sasl-gssapi
sudo yum -y install cyrus-sasl-plain

# Install Cyrus SASL From Source
cd ~
wget https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz
tar xvfz cyrus-sasl-2.1.27.tar.gz
cd cyrus-sasl-2.1.27

sudo mkdir -p /usr/local/cyrus_sasl/2_1_27
sudo chown -R ec2-user:ec2-user /usr/local/cyrus_sasl

sudo mkdir -p /usr/local/lib/pkgconfig
sudo chown -R ec2-user:ec2-user /usr/local/lib/pkgconfig

./configure --prefix=/usr/local/cyrus_sasl/2_1_27
make
make install

# link /usr/local/include
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/libsasl2.la /usr/local/lib/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/libsasl2.so /usr/local/lib/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/libsasl2.so.3 /usr/local/lib/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/libsasl2.so.3.0.0 /usr/local/lib/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/sasl2 /usr/local/lib/

# link /usr/local/lib/pkgconfig
#sudo mkdir -p /usr/local/lib/pkgconfig
sudo ln -s /usr/local/cyrus_sasl/2_1_27/lib/pkgconfig/libsasl2.pc /usr/local/lib/pkgconfig/

# link /usr/local/sbin
sudo ln -s /usr/local/cyrus_sasl/2_1_27/sbin/pluginviewer /usr/local/sbin/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/sbin/saslauthd /usr/local/sbin/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/sbin/sasldblistusers2 /usr/local/sbin/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/sbin/saslpasswd2 /usr/local/sbin/
sudo ln -s /usr/local/cyrus_sasl/2_1_27/sbin/testsaslauthd /usr/local/sbin/

# ===  Install Cloudera HIVE ODBC Driver ===
# ------------------------------------------
echo -e $CYAN "=== Install Cloudera HIVE ODBC Driver ===" $NORMAL
cd ~
wget https://downloads.cloudera.com/connectors/Cloudera_Hive_ODBC_2.6.11/Linux/$CHD_HIVE_RPM

# Hive ODBC RPM installation
sudo yum -y --nogpgcheck localinstall $CHD_HIVE_RPM

sudo yum list | grep ClouderaHiveODBC

# Append the following lines to the /etc/odbcinst.ini file:
echo -e '\n[Cloudera ODBC Driver for Apache Hive 64-bit]' | sudo tee -a /etc/odbcinst.ini
echo -e 'Description=Cloudera ODBC Driver for Apache Hive (64-bit)' | sudo tee -a /etc/odbcinst.ini
echo -e 'Driver=/opt/cloudera/hiveodbc/lib/64/libclouderahiveodbc64.so' | sudo tee -a /etc/odbcinst.ini

# Update the driver configuration file /opt/cloudera/hiveodbc/lib/64/cloudera.hiveodbc.ini
echo -e 'DriverManagerEncoding=UTF-16' | sudo tee -a /opt/cloudera/hiveodbc/lib/64/cloudera.hiveodbc.ini

# ===  Install Cloudera Impala ODBC Driver ===
# ------------------------------------------
echo -e $CYAN "=== Install Cloudera Impala ODBC Driver ===" $NORMAL

wget https://downloads.cloudera.com/connectors/impala_odbc_2.6.14.1016/Linux/$CHD_IMPALA_RPM

# Impala ODBC RPM installation
sudo yum -y --nogpgcheck localinstall $CHD_IMPALA_RPM

# Append the following lines to the /etc/odbcinst.ini file
echo -e '\n[Cloudera ODBC Driver for Impala 64-bit]' | sudo tee -a /etc/odbcinst.ini
echo -e 'Description=Cloudera ODBC Driver for Impala (64-bit)' | sudo tee -a /etc/odbcinst.ini
echo -e 'Driver=/opt/cloudera/impalaodbc/lib/64/libclouderaimpalaodbc64.so' | sudo tee -a /etc/odbcinst.ini
echo -e 'FileUsage = 1' | sudo tee -a /etc/odbcinst.ini

# Update the driver configuration file /opt/cloudera/impalaodbc/lib/64/cloudera.impalaodbc.ini
echo -e 'DriverManagerEncoding=UTF-16' | sudo tee -a /opt/cloudera/impalaodbc/lib/64/cloudera.impalaodbc.ini

# ===  Install Snowflake ODBC Driver ===
# ------------------------------------------
echo -e $CYAN "=== Install Snowflake ODBC Driver ===" $NORMAL

# Create Snowflake odbc repo
sudo touch /etc/yum.repos.d/snowflake-odbc.repo
echo -e '[snowflake-odbc]' | sudo tee -a /etc/yum.repos.d/snowflake-odbc.repo
echo -e 'name=snowflake-odbc' | sudo tee -a /etc/yum.repos.d/snowflake-odbc.repo
echo -e 'baseurl=https://sfc-repo.snowflakecomputing.com/odbc/linux/2.24.2/' | sudo tee -a /etc/yum.repos.d/snowflake-odbc.repo
echo -e 'gpgkey=https://sfc-repo.snowflakecomputing.com/odbc/Snowkey-37C7086698CB005C-gpg' | sudo tee -a /etc/yum.repos.d/snowflake-odbc.repo

# Install Snowflake
sudo yum -y install snowflake-odbc

# ===  Install MySQL ODBC Driver ===
# ------------------------------------------
echo -e $CYAN "=== Install MySQL ODBC Driver ===" $NORMAL

sudo yum -y install mysql-connector-odbc

echo -e '\n[MySQL ODBC 8.0 Unicode Driver]' | sudo tee -a /etc/odbcinst.ini
echo -e 'Driver=/usr/lib64/libmyodbc5w.so' | sudo tee -a /etc/odbcinst.ini
echo -e 'UsageCount=1' | sudo tee -a /etc/odbcinst.ini
echo -e '\n[MySQL ODBC 8.0 ANSI Driver]' | sudo tee -a /etc/odbcinst.ini
echo -e 'Driver=/usr/lib64/libmyodbc5a.so' | sudo tee -a /etc/odbcinst.ini
echo -e 'UsageCount=1' | sudo tee -a /etc/odbcinst.ini

# === Installing Tableau Server === 
# ---------------------------------
echo -e $YELLOW "=== Installing Tableau Server === " $NORMAL

# Save ADMIN_PWD
sudo mkdir -p $MOUNT_POINT/ssh
echo -e "ADMIN_USER=${ADMIN_USER}" | sudo tee $MOUNT_POINT/ssh/keys
$ADMIN_PWD | sudo tee $MOUNT_POINT/ssh/pwd
echo -e "ADMIN_PWD=$(cat $MOUNT_POINT/ssh/pwd)" | sudo tee -a $MOUNT_POINT/ssh/keys
ADMIN_PWD=$(cat $MOUNT_POINT/ssh/keys | grep ADMIN_PWD | cut -d '=' -f 2)

# Save ADMIN_SERVER_PWD
echo -e "ADMIN_SERVER_USER=${ADMIN_SERVER_USER}" | sudo tee -a $MOUNT_POINT/ssh/keys
$ADMIN_SERVER_PWD | sudo tee $MOUNT_POINT/ssh/pwd
echo -e "ADMIN_SERVER_PWD=$(cat $MOUNT_POINT/ssh/pwd)" | sudo tee -a $MOUNT_POINT/ssh/keys
ADMIN_SERVER_PWD=$(cat $MOUNT_POINT/ssh/keys | grep ADMIN_SERVER_PWD | cut -d '=' -f 2)

# Change dir to user path home
cd ~
wget $TS_VER_RMP_LINK

# Change previliges
sudo chmod 755 $TS_VER_RMP

# Insatlling tableau-server rpm pckg
sudo yum -y install $TS_VER_RMP

# ===  Install PsgSQL JAVA Driver ===
echo -e $YELLOW "=== Install PsgSQL JAVA Driver === " $NORMAL
# PsgSQL .jar folder&file configuration 
wget "https://downloads.tableau.com/drivers/linux/postgresql/${PSGSQL_JAR}"
sudo mkdir -p $PSGSQL_DIR
sudo mv ~/$PSGSQL_JAR $PSGSQL_DIR

# === Configure Local Firewall and Port configuration === 
# -------------------------------------------------------
echo -e $PINK "=== Configure Local Firewall and Port configuration ===" $NORMAL

# Install Firewalld [provides a way to configure dynamic firewall rules in Linux]
sudo yum -y install firewalld

# Check dynamic port range. typical range is 8000 to 9000.
#tsm configuration get -k ports.range.min
#tsm configuration get -k ports.range.max

# Start firewalld:
sudo systemctl start firewalld

# Set default zone to 'public'
sudo firewall-cmd --set-default-zone=public -q

# Verify that the default zone is a high-security zone, such as public.
sudo firewall-cmd --get-default-zone

# Add ports for the gateway, tabadmincontroller port and  port range (27000-27010) 
# for  licensing communication between nodes
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=8850/tcp
sudo firewall-cmd --permanent --add-port=27000-27010/tcp
sudo firewall-cmd --permanent --add-port=443/tcp

# Configure the firewall to allow all traffic from the other nodes in the cluster.
sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$HOSTNAME/32 port port=8000-9000 protocol=tcp accept"
sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$HOSTNAME/32 port port=27000-27010 protocol=tcp accept"

#Reload the firewall and verify the settings.
sudo firewall-cmd --reload

# [optional] List Firewall status
sudo firewall-cmd --list-all

# ----------------------------------------------------------------------------------------
# initialize TSM
echo -e $YELLOW "Tableau Server - initializing tsm" $NORMAL
cd /opt/tableau/tableau_server/packages/scripts.*
sudo ./initialize-tsm --accepteula

source /etc/profile.d/tableau_server.sh

echo -e $CYAN "Tableau Server - Creating server administrator user" $NORMAL
sudo usermod -a -G tsmadmin $ADMIN_SERVER_USER --password $ADMIN_SERVER_PWD
echo $ADMIN_SERVER_PWD | sudo passwd --stdin $ADMIN_SERVER_USER

# Check tms installed version 
echo -e $CYAN "Tableau Server - tsm version:" $NORMAL
tsm version

# Activate Trail version
echo -e $PINK "Tableau Server - Activate Trail version:" $NORMAL
tsm licenses activate -t

# Change owner for mount point to 'tableau' 
sudo chown -R $ADMIN_SERVER_USER:$ADMIN_SERVER_USER $MOUNT_POINT

# JSON Templeate creation for registry
cd ~
REG='{
  "zip" : "9999",
  "country" : "XXXX",
  "city" : "XXXX",
  "last_name" : "XXXX",
  "industry" : "XXXX",
  "eula" : "yes",
  "title" : "XXXX",
  "phone" : "XXXX",
  "company" : "XXXX",
  "state" : "XXXX",
  "department" : "XXXX",
  "first_name" : "XXXX",
  "email" : "XXXX"
}'

echo $REG | sudo tee $MOUNT_POINT/registration.json > /dev/null

# Registration with JSON file
echo -e $CYAN "Tableau Server - Registration and configuration:" $NORMAL
tsm register --file $MOUNT_POINT/registration.json

# Configure sample workbook installation [False or True]
tsm configuration set -k install.component.samples -v false

# Import Configuration File
AUTH_CONFIG='{
   "configEntities": {
      "gatewaySettings": {
         "_type": "gatewaySettingsType",
         "port": 80,
         "firewallOpeningEnabled": true,
         "sslRedirectEnabled": true,
         "publicHost": "localhost",
         "publicPort": 80
      },
      "identityStore": {
         "_type": "identityStoreType",
         "type": "local",
         "domain": "XXXX",
         "nickname": "XXXX"
      }
    },
     "configKeys": {
        "gateway.timeout": "900"
     }
}'

echo $AUTH_CONFIG | sudo tee $MOUNT_POINT/auth_config.json > /dev/null

tsm settings import -f $MOUNT_POINT/auth_config.json

# TSM Apply Changes
tsm pending-changes apply

# Initialize and start Tableau Server
echo -e $YELLOW "Tableau Server - Finishing initializing and starting server:" $NORMAL
tsm initialize --start-server --request-timeout 1800

'''
# Enable external file store
tsm stop
tsm topology external-services storage enable -network-share $MOUNT_POINT
'''

# Create an Tableau application admin user
echo -e $CYAN "Tableau Server - Create an Tableau application admin user" $NORMAL
tabcmd initialuser --username $ADMIN_USER --password $ADMIN_PWD --server http://localhost

# Configure SMTP Setup
SMTP='{
"configKeys": {
        "svcmonitor.notification.smtp.server": "'$SMTP_URL'",
        "svcmonitor.notification.smtp.send_account": "''",
        "svcmonitor.notification.smtp.port": 443,
        "svcmonitor.notification.smtp.password": "''",
        "svcmonitor.notification.smtp.ssl_enabled": true,
        "svcmonitor.notification.smtp.from_address": "'$SMTP_MAIL'",
        "svcmonitor.notification.smtp.target_addresses": "'$SMTP_MAIL'",
        "svcmonitor.notification.smtp.canonical_url": "'$SMTP_URL'"
        }
}'

echo $SMTP | sudo tee $MOUNT_POINT/smtp.json > /dev/null
echo -e $CYAN "Tableau Server - Setting SMTP details" $NORMAL
tsm settings import -f $MOUNT_POINT/smtp.json

# === Configure NODE TSM Services: ===
# ------------------------------------
# Increase the value for the backgrounder.querylimit parameter. (20 Hours)
tsm configuration set -k backgrounder.querylimit -v 60000

# Increase the application server Java Virtual machine heap space (Default=1024 MB)
#tsm configuration set -k vizportal.vmopts -v "-XX:+UseConcMarkSweepGC -Xmx2048m -Xms256m -XX:+CrashOnOutOfMemoryError -XX:-CreateMinidumpOnCrash"

# Set 'Backgrounder' to 3 services (defualt=2)
tsm topology set-process -n node1 -pr backgrounder -c 2

# Set 'Cache Server' to 3 services (default=2)
tsm topology set-process -n node1 -pr CacheServer -c 3

# Apply TSM pending-changes on NODE (Force restart) --------------------------------
echo -e $YELLOW "Tableau Server - Applying changes on server..." $NORMAL
tsm pending-changes apply --ignore-prompt

echo -e $GREEN "\n === Tableau Server installation completed! Version: ${TABLEAU_SERVER_VER} ===\n" $NORMAL
echo -e $YELLOW "If you want to change your users admin passwords please run 'sudo passwd [username]'\n" $NORMAL
echo -e "- Follow this link for Tableau Server Web UI: ${PINK} http://${HOSTNAME}"${NORMAL} 
echo -e "- Follow this link for Tableau Server Adminstration Managment Web UI: ${CYAN} https://${HOSTNAME}:8850\n"${NORMAL}
