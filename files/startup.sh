#!/bin/sh
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=`vault auth -method=aws -no-store|grep token:|awk '{ print $NF }'`

if [ x"$instance_type" = x"readwrite" ]; then
    dbuser=`vault read -field=username ${vault_path}/hive_rwuser`
    dbpass=`vault read -field=password ${vault_path}/hive_rwuser`
else
    dbuser=`vault read -field=username ${vault_path}/hive_rouser`
    dbpass=`vault read -field=password ${vault_path}/hive_rouser`
fi

#check if database is initialized, test only from rw instances
if [ x"$instance_type" = x"readwrite" ]; then
schema_version=`echo "select SCHEMA_VERSION from VERSION"|mysql -h$dbhost -u$dbuser -p$dbpass $dbname -N`
if [ x"$schema_version" != x"2.3.0" ]; then
    cd /usr/lib/hive/scripts/metastore/upgrade/mysql
    cat hive-schema-2.3.0.mysql.sql|mysql -h$dbhost -u$dbuser -p$dbpass $dbname -N
    cd /
fi
fi

[[ -z $loglevel ]] && loglevel="INFO"

su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf hive.root.logger=${loglevel},console --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${dbhost}:3306/${dbname} --hiveconf javax.jdo.option.ConnectionUserName=${dbuser} --hiveconf javax.jdo.option.ConnectionPassword=${dbpass}"
