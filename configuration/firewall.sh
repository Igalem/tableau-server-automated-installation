export MASTER_NODE_IP = 0.0.0.0
export SLAVE_NODE_1_IP = 0.0.0.0
export SLAVE_NODE_2_IP = 0.0.0.0

## Firewall configuration 
# Main node:
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_1_IP)/32 port port=8000-9000 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_2_IP)/32 port port=8000-9000 protocol=tcp accept'

# Slave node 1:
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($MASTER_NODE_IP)/32 port port=80 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($MASTER_NODE_IP)/32 port port=8000-9000 protocol=tcp accept'

sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_2_IP)/32 port port=80 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_2_IP)/32 port port=8000-9000 protocol=tcp accept'

# Slave node 2:
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($MASTER_NODE_IP)/32 port port=80 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($MASTER_NODE_IP)/32 port port=8000-9000 protocol=tcp accept'

sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_1_IP)/32 port port=80 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=($SLAVE_NODE_1_IP)/32 port port=8000-9000 protocol=tcp accept'

#Reload the firewall and verify the settings.
sudo firewall-cmd --reload

# [optional] List Firewall status
sudo firewall-cmd --list-all

# Remove reach rule
sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="0.0.0.0/32" port port="8000-9000" protocol="tcp" accept'
sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="0.0.0.0/32" port port="27000-27010" protocol="tcp" accept'
sudo firewall-cmd --reload
sudo firewall-cmd --list-all