
# Overview

For more information please refer to the main [Apiary](https://github.com/ExpediaInc/apiary) project page.

## Environment Variables
|Environment Variable|Required|Description|
|----|----|----|
|AWS_REGION|Yes|AWS region to configure various AWS clients.|
|ENABLE_METRICS|No|Option to enable sending Hive Metastore metrics to CloudWatch.|
|ENABLE_GLUESYNC|No|Option to turn on GlueSync Hive Metastore listener.|
|EXTERNAL_DATABASE|No|Option to enable external database mode, when specified it disables managing Hive Metastore MySQL database schema.|
|GLUE_PREFIX|No|Prefix added to Glue databases to handle database name collisions when synchronizing multiple Hive Metastores to the Glue catalog.|
|HADOOP_HEAPSIZE|No|Hive Metastore Java process heapsize.|
|RANGER_POLICY_MANAGER_URL|No|Ranger admin URL from where policies will be downloaded.|
|RANGER_SERVICE_NAME|No|Ranger service name used to configure RangerAuth plugin.|
|RANGER_AUDIT_DB_URL|No|Ranger audit database JDBC URL.|
|RANGER_AUDIT_SECRET_ARN|No|Ranger audit database secret ARN.|
|RANGER_AUDIT_SOLR_URL|No|Ranger Solr audit URL.|
|LDAP_URL|No|Active Directory URL to enable group mapping in metastore.|
|LDAP_BASE|No|LDAP base DN used to search for user groups.|
|LDAP_SECRET_ARN|No|LDAP bind DN SecretsManager secret ARN.|
|LDAP_CA_CERT|Base64 encoded Certificate Authority Bundle to validate LDAP SSL connection.|
|HIVE_METASTORE_ACCESS_MODE|No|Hive Metastore access mode, applicable values are: readwrite, readonly|
|HIVE_DB_NAMES|No|comma separated list of Hive database names, when specified Hive databases will be created and mapped to corresponding S3 buckets.|
|HIVE_METASTORE_LOG_LEVEL|No|Hive Metastore service Log4j log level.|
|INSTANCE_NAME|Yes|Apiary instance name, will be used as prefix on most AWS resources to allow multiple Apiary instance deployments.|
|MYSQL_DB_HOST|Yes|Hive Metastore MySQL database hostname.|
|MYSQL_DB_NAME|Yes|Hive Metastore MySQL database name.|
|MYSQL_SECRET_ARN|Yes|Hive Metastore MySQL SecretsManager secret ARN.|
|SNS_ARN|No|The SNS topic ARN to which metadata updates will be sent.|

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2018-2019 Expedia Inc.
