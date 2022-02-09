#!/bin/bash
# ----------------------------------------- Setting parameters:
HOSTNAME=$(hostname -i)

# Setup Tableau Server Version for install
TABLEAU_SERVER_VER='2021-4-2'
TS_VER_DIR="${TABLEAU_SERVER_VER//-/.}"
TS_VER_RMP="tableau-server-${TABLEAU_SERVER_VER}.x86_64.rpm"
TS_VER_RMP_LINK="https://downloads.tableau.com/esdalt/${TS_VER_DIR}/${TS_VER_RMP}"
CHD_HIVE_RPM='ClouderaHiveODBC-2.6.11.1011-1.x86_64.rpm'
CHD_IMPALA_RPM='ClouderaImpalaODBC-2.6.14.1016-1.x86_64.rpm'
MOUNT_POINT=/tableau

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

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

# === Automount EBS Volume on Reboot ===
# --------------------------------------
DEVICE=/dev/$(lsblk  --noheadings --raw --sort SIZE | tail -1 | cut -d ' ' -f 1)

sudo mkdir -p $MOUNT_POINT

# Command to create a file system on the volume (Format)
 sudo mkfs -t xfs -f $DEVICE

# # Mount device with path
sudo mount $DEVICE $MOUNT_POINT

# # Automatically mount an attached volume after reboot / For the current task it's not obligatory

# # [optional] - IF THERE ARE Issues only! , remount all
# # ----> sudo mount / -o remount,rw

# # Create a backup of your /etc/fstab
sudo cp /etc/fstab /etc/fstab.orig

UUID=$(sudo blkid | grep $DEVICE | awk -F '\"' '{print $2}')

# # Add entries into /etc/fstab to mount the device at the specified mount point 
sudo bash -c 'echo -e "# Mount device at /tableau_data" >> /etc/fstab'
echo -e "UUID=$(echo $UUID)  $MOUNT_POINT  xfs  defaults,nofail  0  1" | sudo tee -a /etc/fstab

sudo umount $MOUNT_POINT

# # Mount all (remount to validate device attachment)
sudo mount -a

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

# #Change owner for mount point to 'tableau' 
# #cd ~
# #sudo chown $ADMIN_SERVER_USER:$ADMIN_SERVER_USER $MOUNT_POINT


# === Configure Local Firewall and Port configuration === 
# -------------------------------------------------------
echo -e $PINK "=== Configure Local Firewall and Port configuration ===" $NORMAL

# Install Firewalld [provides a way to configure dynamic firewall rules in Linux]
sudo yum -y install firewalld

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

# === Installing Tableau Server (External File Store as option) === 
# -----------------------------------------------------------------
echo -e $YELLOW "=== Installing Tableau Server === " $NORMAL

# Change dir to user path home
cd ~
wget $TS_VER_RMP_LINK

# Change previliges
sudo chmod 755 $TS_VER_RMP

# Insatlling tableau-server rpm pckg
sudo yum -y install $TS_VER_RMP

# Importing initial NODE bootstrap file 
echo -e $PINK "Please import Initial NODE bootstrap file into home path: '~/' before running the additional commands." $NORMAL
echo -e $YELLOW "cd /opt/tableau/tableau_server/packages/scripts.*" $NORMAL
echo -e $YELLOW "sudo ./initialize-tsm -b ~/bootstrap.json --accepteula -f" $NORMAL

'''
##### ------------------------------------------ Additional NODE Attachment ---------------------------------------- ####

tsm topology nodes get-bootstrap-file --file ~/bootstrap.json

### [!!] Copy bootstrap file from NODE1 into ~/ before running the following commands:

# Initialize tsm
cd /opt/tableau/tableau_server/packages/scripts.*

# Initailize TSM with a generate bootstrap file
sudo ./initialize-tsm -b ~/bootstrap.json --accepteula -f

---------------------------------------------------------------------------------------------------------------------------
'''

'''
### --!!!------ GOTO Initial NODE 1 To Complete the Topology Setup -----!!!--- ######

# Set clustercontroller 1 into NODE 
tsm topology set-process -n node1 -pr clustercontroller -c 1

# Apply tsm pending changes
tsm pending-changes apply --ignore-prompt --ignore-warnings

# ------------------------------------------------------------------------------------------------------------------------------ #
# [!!optional!!] - ONLY When attaching 3 NODES !! create coordination service

#tsm topology list-nodes -v
#tsm topology deploy-coordination-service -n node1,node2,node3

#tsm start
# ------------------------------------------------------------------------------------------------------------------------------ #

# Configure Client File Service(CFS) On initial node

## Set file store process only for internal storage
tsm topology set-process -n node3 -pr filestore -c 1 

tsm topology set-process -n node2 -pr clientfileservice -c 1
tsm topology set-process -n node2 -pr gateway -c 0
tsm topology set-process -n node2 -pr vizqlserver -c 2
tsm topology set-process -n node2 -pr vizportal -c 0
tsm topology set-process -n node2 -pr backgrounder -c 3
tsm topology set-process -n node2 -pr cacheserver -c 2
tsm topology set-process -n node2 -pr searchserver -c 0
tsm topology set-process -n node2 -pr dataserver -c 2
tsm topology set-process -n node2 -pr pgsql -c 0


tsm pending-changes apply --ignore-prompt

tsm start

'''