#!/bin/sh
MYSQL_USER=$(echo "$MYSQL_USER_CREDS" | jq -r .username);
MYSQL_PASSWORD=$(echo "$MYSQL_USER_CREDS" | jq -r .password);
MYSQL_MASTER_USER=$(echo "$MYSQL_MASTER_CREDS" | jq -r .username);
MYSQL_MASTER_PASSWORD=$(echo "$MYSQL_MASTER_CREDS" | jq -r .password);
MYSQL_OPTIONS="-h $MYSQL_HOST --user=$MYSQL_MASTER_USER --password=$MYSQL_MASTER_PASSWORD"

echo "Creating GRANT/User for User[${MYSQL_USER}] on Database[${MYSQL_DB}]..."

echo "GRANT $MYSQL_PERMISSIONS ON $MYSQL_DB.* TO '$MYSQL_USER'@\`%\` IDENTIFIED BY '$MYSQL_PASSWORD';" | mysql $MYSQL_OPTIONS &> /dev/null
result=$?

if [ $result -ne 0 ]; then
  echo "Failed to run command [with exit code ${result} from MySQL]"
  echo "Redacted command: [GRANT $MYSQL_PERMISSIONS ON $MYSQL_DB.* TO '$MYSQL_USER'@\`%\` IDENTIFIED BY '<PASSWORD REMOVED>';]"
  exit $result
else 
  echo "Successfully updated MySQL."
fi 
