## ============= DD Custom Alert ==============================================

## Allow API requests for server:
tsm configuration set -k wgserver.systeminfo.allow_referrer_ips -v 0.0.0.0

## pip install xmltodict on DD env.
sudo -Hu dd-agent /opt/datadog-agent/embedded/bin/pip install xmltodict

## Check custom alert
sudo -u dd-agent -- datadog-agent check custom_tsm.py
