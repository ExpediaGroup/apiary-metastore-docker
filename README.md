
# Overview

For more information please refer to the main [Apiary](https://github.com/ExpediaGroup/apiary) project page.

## Environment Variables
|Environment Variable|Required|Description|
|----|----|----|
|APIARY_S3_INVENTORY_PREFIX|No (defaults to `EntireBucketDaily`)|Prefix used by S3 Inventory when creating data in the inventory bucket.|
|APIARY_S3_INVENTORY_TABLE_FORMAT|No (defaults to `ORC`)|Format of S3 inventory data - `ORC`, `Parquet`, or `CSV`|
|APIARY_SYSTEM_SCHEMA|No (defaults to `apiary_system`)|Name for internal system database.|
|AWS_REGION|Yes|AWS region to configure various AWS clients.|
|AWS_WEB_IDENTITY_TOKEN_FILE|No|Path of the AWS Web Identity Token File for IRSA/OIDC AWS authentication.|
|DISALLOW_INCOMPATIBLE_COL_TYPE_CHANGES|No|`true`/`false` value for hive.metastore.disallow.incompatible.col.type.changes, default `true`.|
|ENABLE_GLUESYNC|No|Option to turn on GlueSync Hive Metastore listener.|
|ENABLE_METRICS|No|Option to enable sending Hive Metastore metrics to CloudWatch.|
|ENABLE_S3_INVENTORY|No|Option to create Hive tables on top of S3 inventory data if enabled in `apiary-data-lake`. Enabled if value is not null/empty.|
|ENABLE_S3_LOGS|No|Option to create Hive tables on top of S3 access logs data if enabled in `apiary-data-lake`. Enabled if value is not null/empty.|
|EXTERNAL_DATABASE|No|Option to enable external database mode, when specified it disables managing Hive Metastore MySQL database schema.|
|GLUE_PREFIX|No|Prefix added to Glue databases to handle database name collisions when synchronizing multiple Hive Metastores to the Glue catalog.|
|HADOOP_HEAPSIZE|No|Hive Metastore Java process heapsize.|
|HMS_AUTOGATHER_STATS|No (default is `true`)|Whether or not to create basic statistics on table/partition creation. Valid values are `true` or `false`.|
|LIMIT_PARTITION_REQUEST_NUMBER|No (default is `-1`)|To protect the cluster, this controls how many partitions can be scanned for each partitioned table. The default value "-1" means no limit. The limit on partitions does not affect metadata-only queries.|
|HIVE_METASTORE_ACCESS_MODE|No|Hive Metastore access mode, applicable values are: readwrite, readonly|
|HIVE_DB_NAMES|No|comma separated list of Hive database names, when specified Hive databases will be created and mapped to corresponding S3 buckets.|
|HIVE_METASTORE_LOG_LEVEL|No|Hive Metastore service Log4j log level.|
|HMS_MIN_THREADS|No (defaults to `200`)|Minimum size of the Hive metastore thread pool.|
|HMS_MAX_THREADS|No (defaults to `1000`)|Maximum size of the Hive metastore thread pool.|
|INSTANCE_NAME|Yes|Apiary instance name, will be used as prefix on most AWS resources to allow multiple Apiary instance deployments.|
|KAFKA_BOOTSTRAP_SERVERS|No|Kafka Bootstrap Servers to enable Kafka Metastore listener and send Metastore events to Kafka.|
|KAFKA_CLIENT_ID|No|Kafka label you define that names the Kafka producer.|
|KAFKA_COMPRESSION_TYPE|No|Kafka Compression type, if none is specified there is no compression enabled. Values available are gzip, lz4 and snappy.|
|LDAP_BASE|No|LDAP base DN used to search for user groups.|
|LDAP_CA_CERT|Base64 encoded Certificate Authority Bundle to validate LDAP SSL connection.|
|LDAP_SECRET_ARN|No|LDAP bind DN SecretsManager secret ARN.|
|LDAP_URL|No|Active Directory URL to enable group mapping in metastore.|
|MYSQL_CONNECTION_POOL_SIZE|No (defaults to `10`)|MySQL Connection pool size for Hive Metastore. See [here](https://github.com/apache/hive/blob/master/common/src/java/org/apache/hadoop/hive/conf/HiveConf.java#L1181) for more info.|
|MYSQL_DB_HOST|Yes|Hive Metastore MySQL database hostname.|
|MYSQL_DB_NAME|Yes|Hive Metastore MySQL database name.|
|MYSQL_SECRET_ARN|Yes|Hive Metastore MySQL SecretsManager secret ARN.|
|MYSQL_SECRET_USERNAME_KEY|No (defaults to `username`)|Hive Metastore MySQL SecretsManager secret username key.|
|RANGER_AUDIT_DB_URL|No|Ranger audit database JDBC URL.|
|RANGER_AUDIT_SECRET_ARN|No|Ranger audit database secret ARN.|
|RANGER_AUDIT_SOLR_URL|No|Ranger Solr audit URL.|
|RANGER_POLICY_MANAGER_URL|No|Ranger admin URL from where policies will be downloaded.|
|RANGER_SERVICE_NAME|No|Ranger service name used to configure RangerAuth plugin.|
|SNS_ARN|No|The SNS topic ARN to which metadata updates will be sent.|
|TABLE_PARAM_FILTER|No|A regular expression for selecting necessary table parameters. If the value isn't set, then no table parameters are selected.|

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2018-2019 Expedia, Inc.
