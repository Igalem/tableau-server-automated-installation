# Restore backup on server: tsm maintenance restore --file <file_name> --skip-identity-store-verification
tsm maintenance restore --skip-identity-store-verification --file 

# After restore success - run to initialize admin user
tsm reset
tabcmd initialuser --username 'admin' --password 'adminbi' --server http://localhost