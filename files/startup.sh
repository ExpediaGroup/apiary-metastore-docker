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
        #create glue database
        if [ ! -z $ENABLE_GLUESYNC ]; then
            echo "creating glue database $HIVE_DB"
            aws --region=us-west-2 glue create-database --database-input Name=${GLUEDB_PREFIX}${HIVE_DB},LocationUri=s3://${BUCKET_NAME}/ &> /dev/null
            aws --region=us-west-2 glue update-database --name=${GLUEDB_PREFIX}${HIVE_DB} --database-input "Name=${GLUEDB_PREFIX}${HIVE_DB},LocationUri=s3://${BUCKET_NAME}/,Description=Managed by ${INSTANCE_NAME} datalake."
        fi
    done    
fi
fi

[[ -z $loglevel ]] && loglevel="INFO"

[[ ! -z $SNS_ARN ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},ApiarySNSListener"
[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},ApiaryGlueSync"
#remove leading , when external METASTORE_LISTENERS are not defined
export METASTORE_LISTENERS=$(echo $METASTORE_LISTENERS|sed 's/^,//')
sed "s/METASTORE_LISTENERS/${METASTORE_LISTENERS}/" -i /etc/hive/conf/hive-site.xml

[[ ! -z $DISABLE_DBMGMT ]] && export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},ApiaryDBPreEventListener"
[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},ApiaryGluePreEventListener"
export METASTORE_PRELISTENERS=$(echo $METASTORE_PRELISTENERS|sed 's/^,//')
sed "s/METASTORE_PRELISTENERS/${METASTORE_PRELISTENERS}/" -i /etc/hive/conf/hive-site.xml

export AUX_CLASSPATH="/usr/share/java/mariadb-connector-java.jar:/usr/share/aws/aws-java-sdk/*"
su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf hive.root.logger=${loglevel},console --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${dbhost}:3306/${dbname} --hiveconf javax.jdo.option.ConnectionUserName=${dbuser} --hiveconf javax.jdo.option.ConnectionPassword=${dbpass}"
