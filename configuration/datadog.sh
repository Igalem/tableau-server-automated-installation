### settingrepo /etc/yum.repos.d/jfrog.repo
sudo nano /etc/yum.repos.d/jfrog.repo

## Install agent
sudo yum -y install datadog-agent-1:7.32.1-1.x86_64

## Install project
sudo yum -y install [PROJECT_NAME]

# Create file
sudo nano /tmp/agentapi.sh

# Insert the following lines into /tmp/agentapi.sh:
#!/bin/bash
echo '{
 "dd_api_key": {"value": {DD_KEY}, "error": null},
  "secret2": {"value": null, "error": "could not fetch the secret"}
}'

# Set it needed permissions:
sudo chown -v dd-agent /tmp/agentapi.sh
sudo chmod 700 /tmp/agentapi.sh

# Change /etc/datadog-agent/datadog.yaml to use it. It needs 2 params:
api_key: "ENC[dd_api_key]"
.....
secret_backend_command: "/tmp/agentapi.sh"

# Restart agent
sudo systemctl restart datadog-agent
sudo systemctl status datadog-agent