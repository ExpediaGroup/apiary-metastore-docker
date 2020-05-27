#!/bin/bash
# Copyright (C) 2018-2020 Expedia, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

set -x

[[ -z ${ENABLE_RANGER_LOGS} ]] && exit 0
[[ -z ${HIVE_DB_NAMES} ]] && exit 1

AWS_ACCOUNT=$(aws sts get-caller-identity|jq -r .Account)

[[ -z ${RANGER_LOGS_SCHEMA} ]] && RANGER_LOGS_SCHEMA=s3_logs_hive
[[ -z ${RANGER_LOGS_PREFIX} ]] && RANGER_LOGS_PREFIX=ranger-access-logs
[[ -z ${APIARY_RW_METASTORE_URI} ]] && APIARY_RW_METASTORE_URI=thrift://hms-readwrite.apiary-${AWS_REGION}.lcl:9083

[[ -z $HIVE_METASTORE_LOG_LEVEL ]] && HIVE_METASTORE_LOG_LEVEL="INFO"
sudo sed "s/HIVE_METASTORE_LOG_LEVEL/$HIVE_METASTORE_LOG_LEVEL/" -i /etc/hive/conf/hive-log4j2.properties

#
# Ranger Access Logs are enabled - need to create and repair Ranger access logs tables on top of S3 Ranger access logs Parquet data
#
[[ -z ${RANGER_LOGS_BUCKET} ]] && RANGER_LOGS_BUCKET=$(echo "${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${RANGER_LOGS_SCHEMA}"|tr "_" "-")

# Hive CLI won't run unless /tmp/hive exists and is writeable
# We are doing this in the Dockerfile
# su hive -s /bin/bash -c "mkdir /tmp/hive && chmod 777 /tmp/hive"

# Create and repair S3 ranger access logs tables
RANGER_LOGS_TEMPLATE_FILE=rangerlogs.tpl

RANGER_LOGS_TABLE_HQL_FILE="/tmp/CreateRangerAccessLogsTables.hql"

# Make sure file exists but is empty before we start appending
echo > ${RANGER_LOGS_TABLE_HQL_FILE}
for HIVE_DB in $(echo "$HIVE_DB_NAMES"|tr "," "\n")
do
  APIARY_SCHEMA_BUCKET=$(echo "${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${HIVE_DB}"|tr "_" "-")
  # shellcheck disable=SC2034
  RANGER_LOGS_TABLE=$(echo "${APIARY_SCHEMA_BUCKET}"|tr "-" "_")

  # Check if AWS has written the Hive data files at least once.  If not, skip trying to create/repair the table.
  HIVEDIR=s3://${RANGER_LOGS_BUCKET}/${RANGER_LOGS_PREFIX}/${APIARY_SCHEMA_BUCKET}

  # wc -l will return 1 if dir exists, 0 otherwise. xargs is used here to trim the output of "wc -l" from "     <number>" to just "number"
  HIVEDIREXISTS=$(aws s3 ls "${HIVEDIR}" | wc -l | xargs)
  if [ "$HIVEDIREXISTS" -eq "0" ] ; then
    echo "Ranger Access Logs Hive data for ${APIARY_SCHEMA_BUCKET} doesn't exist yet, skipping create/repair"
  else
    echo "Writing Ranger access logs table create/repair statements for schema: $HIVE_DB"
    # Format the template file with environment variable values defined above.  Unsetting IFS preserves newlines.
    IFS= HQL_STMT=$(eval "echo \"$(cat "${RANGER_LOGS_TEMPLATE_FILE}")\"")


    echo "${HQL_STMT}" >> ${RANGER_LOGS_TABLE_HQL_FILE}
  fi
done

# Run the create/repair statements that we wrote to the .hql file
echo "Creating and repairing Ranger access logs tables..."
#su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --hiveconf hive.metastore.uris=${APIARY_RW_METASTORE_URI} -f ${RANGER_LOGS_TABLE_HQL_FILE}"
/usr/lib/hive/bin/hive --hiveconf hive.metastore.uris="${APIARY_RW_METASTORE_URI}" -f ${RANGER_LOGS_TABLE_HQL_FILE}
echo "Done creating and repairing Ranger access logs tables."