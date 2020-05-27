CREATE EXTERNAL TABLE IF NOT EXISTS ${RANGER_LOGS_SCHEMA}.${RANGER_LOGS_TABLE}(
  id string COMMENT '',
  access string COMMENT '',
  enforcer string COMMENT '',
  agent string COMMENT '',
  repo string COMMENT '',
  reqUser string COMMENT '',
  resource string COMMENT '',
  logType string COMMENT '',
  result int COMMENT '',
  policy int COMMENT '',
  repoType int COMMENT '',
  resType string COMMENT '',
  action string COMMENT '',
  evtTime timestamp COMMENT '',
  agentHost string COMMENT '',
  _ttl_ string COMMENT '',
  _expire_at_ timestamp COMMENT '',
  _version_ bigint COMMENT '',
  event_count int COMMENT '',
  seq_num int COMMENT '')
PARTITIONED BY (
  dt string)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://${RANGER_LOGS_BUCKET}/${RANGER_LOGS_PREFIX}/${APIARY_SCHEMA_BUCKET}/';

MSCK REPAIR TABLE ${RANGER_LOGS_SCHEMA}.${RANGER_LOGS_TABLE};
