## ---- Steps on Master node -----
# Generate bootstrap file on the initial node
tsm topology nodes get-bootstrap-file --file bootstrap.json

# Copy bootstrap.json from Main host into this server
scp ./bootstrap.json ec2-user@0.0.0.0:~/

# [optional] ---!! ONLY IF TABLEAU SERVER ALREADY INSTALLED !! --
sudo /opt/tableau/tableau_server/packages/scripts.<version_code>/tableau-server-obliterate -a -y -y -y -l

cd ~
sudo ./initialize-tsm -b ~/bootstrap.json --accepteula -f

## ---- Steps on Slave node (attachment node) -----
# Initailize TSM with a generate bootstrap file
sudo ./initialize-tsm -b ~/bootstrap.json --accepteula -f