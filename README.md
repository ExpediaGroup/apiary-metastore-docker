
# Overview

For more information please refer to the main [Apiary](https://github.com/ExpediaInc/apiary) project page.

## Variables
|Environment Variable|Required|Description|
|----|----|----|
|AWS_REGION|Yes|AWS region to configure various AWS clients.|
|VAULT_ADDR|Yes|Address of Vault server for secrets.|
|VAULT_LOGIN_PATH|No|Alternative login path on Vault server.|
|vault_path|Yes|Vault path to read secrets from.|
|ENABLE_METRICS|No|Option to enable sending Hive Metastore metrics to CloudWatch.|
|SNS_ARN|No|The SNS topic ARN to which metadata updates will be sent.|
|ENABLE_GLUESYNC|No|Option to turn on GlueSync Hive Metastore listener.|
|GLUE_PREFIX|No|Prefix added to Glue databases to handle database name collisions when synchronizing multiple Hive Metastores to the Glue catalog.|
|POLICY_MGR_URL|No|Ranger admin URL from where policies will be downloaded.|
|RANGER_SERVICE_NAME|No|Ranger service name used to configure RangerAuth plugin.|
|AUDIT_DB_URL|No|Ranger audit database JDBC URL.|
|LDAP_URL|No|Active Directory URL to enable group mapping in metastore.|
|LDAP_BASE|No|LDAP base dn used to search for user groups.|
|instance_type|No|Hive Metastore instance type, applicable values are: readwrite, readonly|
|INSTANCE_NAME|Yes|Apiary instance name, will be used as prefix on most AWS resources to allow multiple Apiary instance deployments.|
|HIVE_DBS|No|CSV list of hive schema names, when specified hive schemas will be created and mapped to corresponding S3 buckets.|
|EXTERNAL_DATABASE|No|Option to enable external database mode, when specified it disables managing Hive Metastore mysql database schema.|
|loglevel|No|Hive Metastore service log4j log level.|

# Contact

## Mailing List
If you would like to ask any questions about or discuss Apiary please join our mailing list at

  [https://groups.google.com/forum/#!forum/apiary-user](https://groups.google.com/forum/#!forum/apiary-user)

# Legal
This project is available under the [Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html).

Copyright 2018 Expedia Inc.
