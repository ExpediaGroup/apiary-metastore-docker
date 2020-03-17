#!/bin/bash
# Copyright (C) 2018-2020 Expedia, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

[[ -z ${ENABLE_S3_INVENTORY} ]] && exit 0
[[ -z ${HIVE_DB_NAMES} ]] && exit 1

AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`

[[ -z ${APIARY_S3_INVENTORY_SCHEMA} ]] && APIARY_S3_INVENTORY_SCHEMA=s3_inventory
[[ -z ${APIARY_S3_INVENTORY_PREFIX} ]] && APIARY_S3_INVENTORY_PREFIX=EntireBucketDaily
[[ -z ${APIARY_S3_INVENTORY_TABLE_FORMAT} ]] && APIARY_S3_INVENTORY_TABLE_FORMAT=ORC
[[ -z ${APIARY_RW_METASTORE_URI} ]] && APIARY_RW_METASTORE_URI=thrift://hms-readwrite.apiary-${AWS_REGION}.lcl:9083

[[ -z $HIVE_METASTORE_LOG_LEVEL ]] && HIVE_METASTORE_LOG_LEVEL="INFO"
sed "s/HIVE_METASTORE_LOG_LEVEL/$HIVE_METASTORE_LOG_LEVEL/" -i /etc/hive/conf/hive-log4j2.properties

#
# S3 Inventory is enabled - need to create and repair inventory tables on top of S3 inventory data that AWS wrote.
#

# Hive CLI won't run unless /tmp/hive exists and is writeable
su hive -s /bin/bash -c "mkdir /tmp/hive && chmod 777 /tmp/hive"

# Create and repair S3 inventory tables
APIARY_S3_INVENTORY_TEMPLATE_FILE=s3inventory.tpl
APIARY_S3_INVENTORY_BUCKET=$(echo "${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${APIARY_S3_INVENTORY_SCHEMA}"|tr "_" "-")
APIARY_S3_INVENTORY_TABLE_FORMAT=`echo $APIARY_S3_INVENTORY_TABLE_FORMAT | tr "[:upper:]" "[:lower:]"`

if [ "${APIARY_S3_INVENTORY_TABLE_FORMAT}" = "parquet" ]; then
  APIARY_S3_INVENTORY_TABLE_SERDE=org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe
elif [ "${APIARY_S3_INVENTORY_TABLE_FORMAT}" = "csv" ] ; then
  APIARY_S3_INVENTORY_TABLE_SERDE=org.apache.hadoop.hive.serde2.OpenCSVSerde
else
  APIARY_S3_INVENTORY_TABLE_SERDE=org.apache.hadoop.hive.ql.io.orc.OrcSerde
fi
APIARY_S3_INVENTORY_TABLE_HQL_FILE="/CreateInventoryTables.hql"

> ${APIARY_S3_INVENTORY_TABLE_HQL_FILE}
for HIVE_DB in `echo $HIVE_DB_NAMES|tr "," "\n"`
do
  APIARY_SCHEMA_BUCKET=$(echo "${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${HIVE_DB}"|tr "_" "-")
  APIARY_S3_INVENTORY_TABLE=$(echo "${APIARY_SCHEMA_BUCKET}"|tr "-" "_")

  # Check if AWS has written the Hive data files at least once.  If not, skip trying to create/repair the table.
  HIVEDIR=s3://${APIARY_S3_INVENTORY_BUCKET}/${APIARY_SCHEMA_BUCKET}/${APIARY_S3_INVENTORY_PREFIX}/hive

  # wc -l will return 1 if dir exists, 0 otherwise. xargs is used here to trim the output of "wc -l" from "     <number>" to just "number"
  HIVEDIREXISTS=`aws s3 ls ${HIVEDIR} | wc -l | xargs`
  if [ "$HIVEDIREXISTS" -eq "0" ] ; then
    echo "S3 Inventory Hive data for ${APIARY_SCHEMA_BUCKET} doesn't exist yet, skipping create/repair"
  else
    echo "Writing S3 inventory table create/repair statements for schema: $HIVE_DB"
    # Format the template file with environment variable values defined above.  Unsetting IFS preserves newlines.
    IFS= HQL_STMT=`eval "echo \"$(cat "${APIARY_S3_INVENTORY_TEMPLATE_FILE}")\""`

    echo ${HQL_STMT} >> ${APIARY_S3_INVENTORY_TABLE_HQL_FILE}
  fi
done

# Run the create/repair statements that we wrote to the .hql file
echo "Creating and repairing S3 inventory tables..."
su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --hiveconf hive.metastore.uris=${APIARY_RW_METASTORE_URI} -f ${APIARY_S3_INVENTORY_TABLE_HQL_FILE}"
echo "Done creating and repairing S3 inventory tables."
