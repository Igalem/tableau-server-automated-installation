## Export site by [site-id] (exp: "Default")
tsm sites export --overwrite --request-timeout 30000 --site-id Default --file export.zip

## Unlock Site by [site-id] (exp: "Default")
tsm sites unlock --site-id Default

## List Execution jobs:
tsm jobs list



## Import site:
tsm sites import --request-timeout 30000 --site-id tableau_old --file export.zip


## Changing import file path: (No restart requiered)
tsm configuration set -k basefilepath.site_import.exports -v /tableau_data/export

## Apply changes 
tsm pending-changes apply
