#!/bin/sh

# MYSQL All permissions are in MYSQL_DB_USERNAME & MYSQL_DB_PASSWORD 
# Extracted credentials from vault are HM_MYSQL_USER_READONLY_USERNAME & HM_MYSQL_USER_READONLY_PASSWORD
MYSQL_OPTIONS="-h $MYSQL_DB_HOST --user=$HM_MYSQL_USER_READONLY_USERNAME --password=$HM_MYSQL_USER_READONLY_PASSWORD"

echo "Creating GRANT/User for User[${HM_MYSQL_USER_READONLY_USERNAME}] on Database[${MYSQL_DB_NAME}]..."

echo "GRANT $MYSQL_PERMISSIONS ON $MYSQL_DB_NAME.* TO '$HM_MYSQL_USER_READONLY_USERNAME'@\`%\` IDENTIFIED BY '$HM_MYSQL_USER_READONLY_PASSWORD';" | mysql $MYSQL_OPTIONS &> /dev/null
result=$?

if [ $result -ne 0 ]; then
  echo "Failed to run command [with exit code ${result} from MySQL]"
  echo "Redacted command: [GRANT $MYSQL_PERMISSIONS ON $MYSQL_DB_NAME.* TO '$HM_MYSQL_USER_READONLY_USERNAME'@\`%\` IDENTIFIED BY '<PASSWORD REMOVED>';]"
  exit $result
else 
  echo "Successfully updated MySQL."
fi 
