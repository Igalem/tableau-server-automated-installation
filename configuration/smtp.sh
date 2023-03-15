
SMTP_URL="xxxxx.gmail.com"
SMTP_MAIL="xxx@xxx.com"

SMTP='{"configKeys": {"svcmonitor.notification.smtp.server": "'$SMTP_URL'",
        "svcmonitor.notification.smtp.ssl_enabled": true,
        "svcmonitor.notification.smtp.port": 443,
        "svcmonitor.notification.smtp.from_address": "'$SMTP_MAIL'",
        "svcmonitor.notification.smtp.target_addresses":  "'$SMTP_MAIL'""
        }}'

# Create smtp.json:
echo $SMTP > ~/smtp.json

# Config smtp via tsm and json file
tsm settings import -f ~/smtp.json


echo '{...}' | sudo tee smtp.json > /dev/null
echo $SMTP | sudo tee smtp.json > /dev/null


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