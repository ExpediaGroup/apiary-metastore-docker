# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- deploy SNS Listener from [apiary-metastore-extensions](https://github.com/ExpediaInc/apiary-extensions/tree/master/apiary-metastore-listener)
- Additional check to support external MySQL database for Hive Metastore, required to implement [#48](https://github.com/ExpediaInc/apiary-metastore/issues/48).

### Fixed
- Fix to update cacerts for Java.
