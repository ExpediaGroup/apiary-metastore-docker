# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html). 

## [5.2.9] - 2025-09-10
### Added
- Updating all `APIARY_EXTENSIONS` modules to `8.1.11` (was `8.1.7`). Improved glue listener.
- Fix Maven download repository and upgrade Maven to `3.9.11` (was `3.9.4`).

## [5.2.8] - 2025-05-21
### Added
- Updating all `APIARY_EXTENSIONS` modules to `8.1.7` (was `8.1.4`). Updated kafka-clients to latest version.

## [5.2.7] - 2025-05-05
### Added
- Updating all `APIARY_EXTENSIONS` modules to `8.1.4` (was `8.1.3`). Improved RENAME support in Glue listener. 

## [5.2.6] - 2025-04-22
### Added
- Updating all `APIARY_EXTENSIONS` modules to `8.1.3` (was `8.1.2`). Added RENAME support in Glue listener. 

## [5.2.5] - 2025-04-08
### Added
- Updating `APIARY_EXTENSIONS_VERSION` to `8.1.2` (was `8.1.0`). Fixes in apiary extensions multiple listener functionality.

## [5.2.4] - 2025-04-01
### Added
- Updating `APIARY_EXTENSIONS_VERSION` to `8.1.0` (was `8.0.2`). Supports MSK cluster.

## [5.2.3] - 2025-02-25
### Added
- Option to start gluesync listener without intializing glue databases.

## [5.2.2] - 2024-09-24
### Added
- Upgrade Apiary extensions to 8.0.2 (was 7.3.9). (Glue Listener fix)

## [5.2.1] - 2024-08-23
### Added
- Upgrade yum repos from EMR-5.36.2 (latest EMR 5 version)

## [5.2.0] - 2024-08-22
### Added
- Upgrade HMS to 2.3.9 (was 2.3.7)

## [5.1.0] - 2024-06-24
### Added
- Added `datanucleus.connectionPoolingType` to hive-site.xml, defaults: `BoneCP`
- Added `DATANUCLEUS_CONNECTION_POOLING_TYPE` to support changing the database connection pooling. Valid options are `BoneCP`, `DBCP`, `DBCP2`, `C3P0`, `HikariCP`.
- Added `DATANUCLEUS_CONNECTION_POOL_MAX_POOLSIZE` - Maximum pool size for the connection pool.
- Added `DATANUCLEUS_CONNECTION_POOL_MIN_POOLSIZE` - Minimum pool size for the connection pool.
- Added `DATANUCLEUS_CONNECTION_POOL_INITIAL_POOLSIZE` - Initial pool size for the connection pool (C3P0 only).
- Added `DATANUCLEUS_CONNECTION_POOL_MAX_IDLE` - Maximum idle connections for the connection pool.
- Added `DATANUCLEUS_CONNECTION_POOL_MIN_IDLE` - Minimum idle connections for the connection pool.
- Added `DATANUCLEUS_CONNECTION_POOL_MIN_ACTIVE` - Maximum active connections for the connection pool (DBCP/DBCP2 only).
- Added `DATANUCLEUS_CONNECTION_POOL_MAX_WAIT` - Maximum wait time for the connection pool (DBCP/DBCP2 only).
- Added `DATANUCLEUS_CONNECTION_POOL_VALIDATION_TIMEOUT` - Validation timeout for the connection pool (DBCP/DBCP2/HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_LEAK_DETECTION_THRESHOLD` - Leak detection threshold for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_LEAK_MAX_LIFETIME` - Maximum lifetime for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_AUTO_COMMIT` - Auto commit for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_IDLE_TIMEOUT` - Idle timeout for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_CONNECTION_WAIT_TIMEOUT` - Connection wait timeout for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_READ_ONLY` - Read only mode for the connection pool (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_NAME` - Connection pool name (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_CATALOG` - Connection pool catalog (HikariCP only).
- Added `DATANUCLEUS_CONNECTION_POOL_REGISTER_MBEANS` - Register MBeans for the connection pool (HikariCP only).

## [5.0.1] - 2024-06-19
### Fixed
- Added `MYSQL_DRIVER_JAR` to add the driver connector JAR to the system classpath. By default it is now using `/usr/share/java/mysql-connector-java.jar`.

## [5.0.0] - 2024-06-19 [YANKED]
### Changed
- Switch from mariadb driver to default mysql driver. (Override settings to keep using mariadb driver).
### Added
- Added `MYSQL_CONNECTION_DRIVER_NAME` to support use different connection driver, defaults: `com.mysql.jdbc.Driver`.
- Added `MYSQL_TYPE` to support use different type of MySQL, defaults: `mysql`.
- Added `mysql-connector-java` to support to use driver `com.mysql.jdbc.Driver`.

## [4.0.1] - 2024-06-03
### Changed
- Upgraded `APIARY_EXTENSIONS_VERSION` to `7.3.9` (was `7.3.8`).
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.9` (was `7.3.8`).

## [4.0.0] - 2024-02-06
### Added
- Enables JMX (Java Management Extensions) on Hadoop clients, allowing for remote monitoring and management of JVM-related metrics
### Removed
- CloudWatch metrics in favour of JMX Prometheus Exporter.

## [3.0.17] - 2024-01-31
### Added
- Enable prometheus jmx agent when running on ECS by exporting `EXPORTER_OPTS`

## [3.0.16] - 2024-01-11
### Added
- Added snapshot.yaml for pushing docker image from feature branch.

## [3.0.15] - 2023-10-03
### Fixed
- Safeguard AWS account id call to prevent incorrect DB locations.

## [3.0.14] - 2023-08-11
### Changed
- Upgrade Maven version from `3.9.3` to `3.9.4` as the older version no longer supported.(https://dlcdn.apache.org/maven/maven-3/)

## [3.0.13] - 2023-08-09
### Added
- [issue-118](https://github.com/ExpediaGroup/apiary-metastore-docker/issues/118) Added variable `ENABLE_HIVE_LOCK_HOUSE_KEEPER` to support hive lock house keeper. See more details here: apache/iceberg#2301

## [3.0.12] - 2023-08-02
### Added
- Added variable `MAX_REQUEST_SIZE` to optionally increase the request size when sending records to Kafka.
- Upgraded `APIARY_EXTENSIONS_VERSION` to `7.3.8` (was `7.3.7`).
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.8` (was `7.3.7`).

## [3.0.11] - 2023-07-25
### Added
- Added variable `KAFKA_COMPRESSION_TYPE` to optionally add compression type when sending Metastore events to Kafka through apiary-metastore-listener library.
- Upgraded `APIARY_EXTENSIONS_VERSION` to `7.3.7` (was `7.3.4`).
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.7` (was `7.3.6`).

## [3.0.10] - 2023-06-28
### Added
- Added variable `LIMIT_PARTITION_REQUEST_NUMBER` to protect the cluster, this controls how many partitions can be scanned for each partitioned table. The default value "-1" means no limit. The limit on partitions does not affect metadata-only queries.
### Changed
- Upgraded github actions ubuntu runner to `22.04` (was `18.04`).
- Set `amazonlinux` version to `2` (was `latest`).
- Upgraded mvn version to `3.9.3`(was `3.6.3`). 

## [3.0.9] - 2022-11-23
### Added
- Variable `MYSQL_SECRET_USERNAME_KEY` for pulling aws credentials where the key is set to something other than `username`. Defaults to `username`.  

## [3.0.8] - 2022-11-15
### Changed
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.6` (was `7.3.5`). It fixes a bug in sortOrders when syncing up Iceberg tables.

## [3.0.7] - 2022-11-11
### Changed
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.5` (was `7.3.4`). It fixes a bug in parsing the table parameter - `lastAccessTime` when  syncing up Iceberg tables.

## [3.0.6] - 2022-11-02
### Changed
- Upgraded `APIARY_EXTENSIONS_VERSION` to `7.3.4` (was `6.0.1`).
- Upgraded `APIARY_GLUESYNC_LISTENER_VERSION` to `7.3.4` (was `7.3.0`).

## [3.0.5] - 2022-05-25
### Changed
- LDAP Credentials now can be loaded directly using `LDAP_USERNAME` and `LDAP_PASSWORD`, this is useful to load them from Vault.

## [3.0.4] - 2022-05-24
### Changed
- Upgrade `apiary-gluesync-listener` version to `7.3.0` (was `4.2.0`).

## [3.0.3] - 2022-05-20
### Added
- Add ability to configure size of HMS MySQL connection pool, and configure stats computation on table/partition creation.

## [3.0.2] - 2022-03-29
### Changed
- Upgrade EMR repository to version `5.31.0` (was `5.30.2`) so `AWS SDK for Java` library is upgraded to `1.11.852` that enables AWS web identity token file file authentication using hadoop and public constructors.

## [3.0.1] - 2022-03-28
### Changed
- Enable authentication via `WebIdentityTokenCredentialsProvider`.

## [3.0.0] - 2022-03-25
### Changed
- Upgrade EMR repository to version `5.30.2` (was `5.24.0`) so `AWS SDK for Java` library is upgraded to `1.11.759` and in that way support authentication using IAM role via an OIDC web identity token file (https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html).

## [2.0.3] - 2021-12-16
### Changed
- Modified log4j2 security script to reduce container startup time.

## [2.0.2] - 2021-12-16
### Added
- Added script to find and remove vulnerable log4j2 classes in order to mitigate security issue [CVE-2021-44228](https://nvd.nist.gov/vuln/detail/CVE-2021-44228).

## [2.0.1] - 2021-07-07
### Changed
- Allow override of `hive.metastore.disallow.incompatible.col.type.changes=true` property. 

## [2.0.0] - 2021-05-06
### Changed
- Remove Atlas MetaStore listener in favor of internal processes that subscribe to the Kafka HMS event listener and push changes to Ranger.

Note: This release is a *BREAKING* change that removes all support for the Apache Atlas HMS listener.

## [1.17.1] - 2020-11-18
### Changed
- Enabled ranger audit log summarization.

## [1.17.0] - 2020-09-02
### Added
- Add `allow-grant.sh` to main container.
- Add `db-iam-user.sh` to main container.

### Removed
- Removed `initContainer` in favor of a single image.

## [1.16.0] - 2020-08-31
### Added
- [Issue-165](https://github.com/ExpediaGroup/apiary-data-lake/issues/165) Add init container dockerfile for supporting air-gapped environments.

## [1.15.0] - 2020-06-16
### Added
Create Hive database `apiary_system` on startup. Data for Ranger access logs goes to bucket `<prefix>-apiary-system` in Parquet format.
This is pre-work to prepare for Ranger access-log Hive tables in a future version of Apiary.

## [1.14.0] - 2020-05-11
### Added
- Enable caller to set min and max size of the Hive metastore thread pool.  If not set, defaults to 200/1000 (Hive defaults).

## [1.13.0] - 2020-04-21
### Added
- If S3 access logs are enabled in `apiary-data-lake`, create Hive database `s3_logs_hive` on startup. Raw logs go to bucket `<prefix>-s3-logs` and Hive Parquet data to bucket `<prefix>-s3-logs-hive`.  This is pre-work to prepare for S3 access-log Hive tables in a future version of Apiary.

## [1.12.0] - 2020-04-02
### Changed
- Updated `apiary-metastore-listener` version to `6.0.1` (was `6.0.0`).

## [1.11.0] - 2020-03-17
### Added
- If S3 Inventory is enabled in `apiary-data-lake`, create Hive `s3_inventory` database on startup.
- Add script `/s3_inventory_repair.sh` which can be used as the entrypoint of this Docker image to create and repair S3
  inventory tables in the inventory database (if S3 inventory is enabled). The intent is to run the image this way on a
  scheduled basis in Kubernetes after AWS creates new inventory partition files in S3 each day.

## [1.10.0] - 2020-03-16
### Changed
- Updated `apiary-metastore-listener` and `kafka-metastore-listener` versions to `6.0.0` (was `5.0.2`).

## [1.9.0] - 2020-02-10
### Added
- Enable Prometheus exporter when running on Kubernetes instead of sending metrics to CloudWatch.

## [1.8.0] - 2020-02-06
### Added
- Added an optional Apiary metastore listener which can be used to send Hive metadata events to a Kafka topic.

## [1.7.0] - 2020-02-05

### Changed
- Updated `apiary-metastore-listener` version to `5.0.2` (was `4.2.0`).

## [1.6.0] - 2020-02-04

### Added
- Set EKS hostname to ECS_TASK_ID required for enabling metastore metrics.

### Changed
- Update using https for maven central repository as it no longer supports insecure communication over plain HTTP.

## [1.5.1] - 2020-01-10

### Changed
- Fix Ranger Solr auditing by upgrading `apiary-extensions` version to `5.0.1` (was `5.0.0`)

## [1.5.0] - 2019-12-10

### Added
- Atlas cluster name is set to Apiary `ATLAS_CLUSTER_NAME` env variable when using Atlas plugin. If not set, will default to `INSTANCE_NAME` var.

### Changed
- Update Ranger version from to `2.0.0` (was `1.1.0`).
- Update Ranger metastore plugin to `5.0.0` (was `4.2.0`).
- Support Ranger audit-only mode for read-only HMS endpoint when audit destination is SOLR.

## [1.4.0] - 2019-11-18

### Added
- Add Atlas hive-bridge metastore listener, to send metadata events to Kafka.

## [1.3.1] - 2019-11-12

### Changed
- set DefaultAWSCredentialsProviderChain as default hadoop-aws credential provider.

## [1.3.0] - 2019-09-09

### Changed
- Updated `emr-apps.repo` to `5.24.0` (was `5.15.0`).
- Updated `emr-platform.repo` to `1.17.0` (was `1.6.0`).

### Fixed
- Upgrade Hive to `2.3.4` (was `2.3.3`) in order to fix
  https://issues.apache.org/jira/browse/HIVE-18767 - see
  [#59](https://github.com/ExpediaGroup/apiary-metastore-docker/issues/59)
  (Hive version is controlled by the version of `emr-apps.repo`).

## [1.2.0] - 2019-08-08

### Added
- If Ranger is configured on the metastore, the read-only instance of
  the metastore will be configured for audit-only by using
  `ApiaryRangerAuthAllAccessPolicyProvider` in
  [apiary-metastore-ranger-plugin](https://github.com/ExpediaGroup/apiary-extensions/blob/master/apiary-ranger-metastore-plugin/src/main/java/com/expediagroup/apiary/extensions/rangerauth/policyproviders/ApiaryRangerAuthAllAccessPolicyProvider.java)

## [1.1.0] - 2019-05-09

### Added
- ReadOnlyAuth Pre Event Listener to manage Hive database whitelist in read-only metastores [apiary-metastore-extensions](https://github.com/ExpediaGroup/apiary-extensions/tree/master/apiary-metastore-auth).
- Support for `_` in `HIVE_DB_NAMES` variable. Fixes [#5] (https://github.com/ExpediaGroup/apiary/issues/5).

### Changed
- Updated apiary-metastore-listener to 4.0.0 (was 1.1.0).
- Updated apiary-gluesync-listener to 4.0.0 (was 1.1.0).
- Updated apiary-ranger-plugin to 4.0.0 (was 1.1.0).
- Updated apiary-metastore-metrics to 4.0.0 (was 1.1.0).
- Updated apiary-metastore-auth to 4.0.0 (was 1.1.0).

## [1.0.1] - 2019-02-15

### Added
- Auto configure Hive metastore heapsize when running on ECS.

### Changed
- Replace EMRFS with hadoop-aws S3A libraries.

## [1.0.0] - 2018-10-31

### Added
- Option to send metastore metrics to CloudWatch - see [#4](https://github.com/ExpediaGroup/apiary-metastore-docker/issues/4).
- Refactor Environment variable names.
- Migrate secrets from Hashicorp Vault to AWS SecretsManager.
- Update startup script to configure Log4j, to fix sending Hive Metastore logs to CloudWatch.

### Changed
- Deploy RangerAuth Pre Event Listener from [apiary-metastore-extensions](https://github.com/ExpediaGroup/apiary-extensions/tree/master/apiary-ranger-metastore-plugin).
- Deploy GlueSync Listener from [apiary-metastore-extensions](https://github.com/ExpediaGroup/apiary-extensions/tree/master/apiary-gluesync-listener).
- Deploy SNS Listener from [apiary-metastore-extensions](https://github.com/ExpediaGroup/apiary-extensions/tree/master/apiary-metastore-listener).
- Additional check to support external MySQL database for Hive Metastore, required to implement [#48](https://github.com/ExpediaGroup/apiary-metastore/issues/48).

### Fixed
- Fix to update cacerts for Java.
- Fix Hive Metastore logging.
