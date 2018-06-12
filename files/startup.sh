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
MYSQL_OPTIONS="-h$dbhost -u$dbuser -p$dbpass $dbname -N"
schema_version=`echo "select SCHEMA_VERSION from VERSION"|mysql $MYSQL_OPTIONS`
if [ x"$schema_version" != x"2.3.0" ]; then
    cd /usr/lib/hive/scripts/metastore/upgrade/mysql
    cat hive-schema-2.3.0.mysql.sql|mysql $MYSQL_OPTIONS
    cd /
fi
#create hive databases
if [ ! -z $HIVE_DBS ]; then
    for HIVE_DB in `echo $HIVE_DBS|tr "," "\n"`
    do
        echo "creating hive database $HIVE_DB"
        DB_ID=`echo "select MAX(DB_ID)+1 from DBS"|mysql $MYSQL_OPTIONS`
        AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`
        BUCKET_NAME="${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${HIVE_DB}"
        echo "insert into DBS(DB_ID,DB_LOCATION_URI,NAME,OWNER_NAME,OWNER_TYPE) values(\"$DB_ID\",\"s3://${BUCKET_NAME}/\",\"${HIVE_DB}\",\"root\",\"USER\") on duplicate key update DB_LOCATION_URI=\"s3://${BUCKET_NAME}/\";"|mysql $MYSQL_OPTIONS
    done    
fi
fi

[[ -z $loglevel ]] && loglevel="INFO"

su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf hive.root.logger=${loglevel},console --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${dbhost}:3306/${dbname} --hiveconf javax.jdo.option.ConnectionUserName=${dbuser} --hiveconf javax.jdo.option.ConnectionPassword=${dbpass}"
