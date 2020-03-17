CREATE EXTERNAL TABLE IF NOT EXISTS ${APIARY_S3_INVENTORY_SCHEMA}.${APIARY_S3_INVENTORY_TABLE}(
  bucket string,
  key string,
  version_id string,
  is_latest boolean,
  is_delete_marker boolean,
  size bigint,
  last_modified_date timestamp,
  e_tag string,
  storage_class string,
  intelligent_tiering_access_tier string
  )
PARTITIONED BY (dt string)
ROW FORMAT SERDE '${APIARY_S3_INVENTORY_TABLE_SERDE}'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.SymlinkTextInputFormat'
OUTPUTFORMAT  'org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat'
LOCATION 's3://${APIARY_S3_INVENTORY_BUCKET}/${APIARY_SCHEMA_BUCKET}/${APIARY_S3_INVENTORY_PREFIX}/hive/';

MSCK REPAIR TABLE ${APIARY_S3_INVENTORY_SCHEMA}.${APIARY_S3_INVENTORY_TABLE};
