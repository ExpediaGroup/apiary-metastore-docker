# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

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
