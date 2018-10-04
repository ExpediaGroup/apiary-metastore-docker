#!/bin/sh
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=`vault login -method=aws -path=${VAULT_LOGIN_PATH} -token-only`

if [ x"$instance_type" = x"readwrite" ]; then
    dbuser=`vault read -field=username ${vault_path}/hive_rwuser`
    dbpass=`vault read -field=password ${vault_path}/hive_rwuser`
else
    dbuser=`vault read -field=username ${vault_path}/hive_rouser`
    dbpass=`vault read -field=password ${vault_path}/hive_rouser`
fi

#configure LDAP group mapping, required for ranger authorization
if [[ -n $LDAP_URL ]] ; then
    sed "s/LDAP_BIND_USER/$(vault read -field=bind_user ${vault_path}/ldap_user)/" -i /etc/hadoop/conf/core-site.xml
    vault read -field=bind_password ${vault_path}/ldap_user > /etc/hadoop/conf/ldap-password.txt
    sed 's/org.apache.hadoop.security.JniBasedUnixGroupsMappingWithFallback/org.apache.hadoop.security.LdapGroupsMapping/' -i /etc/hadoop/conf/core-site.xml
    sed "s/LDAP_URL/${LDAP_URL}/" -i /etc/hadoop/conf/core-site.xml
    sed "s/LDAP_BASE/${LDAP_BASE}/" -i /etc/hadoop/conf/core-site.xml
    #configure local ca certificate to connect o ldap/ad
    vault read -field=cacert ${vault_path}/ldap_user > /etc/pki/ca-trust/source/anchors/ldapca.crt
    update-ca-trust
    update-ca-trust enable
fi

#configure ranger authorization
if [[ -n $POLICY_MGR_URL ]]; then
    export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expedia.apiary.extensions.rangerauth.listener.ApiaryRangerAuthPreEventListener"
    sed "s/POLICY_MGR_URL/${POLICY_MGR_URL}/" -i /etc/hive/conf/ranger-hive-security.xml
    sed "s/RANGER_SERVICE_NAME/${RANGER_SERVICE_NAME}/" -i /etc/hive/conf/ranger-hive-security.xml
fi
#enable ranger auditing
if [[ -n $AUDIT_SOLR_URL ]]; then
    sed -e '/xasecure.audit.is.enabled/ { n; s/false/true/ }' -e '/xasecure.audit.solr.is.enabled/ { n; s/false/true/ }' -i /etc/hive/conf/ranger-hive-audit.xml
    sed "s/AUDIT_SOLR_URL/${AUDIT_SOLR_URL}/" -i /etc/hive/conf/ranger-hive-audit.xml
fi
#enable ranger db auditing
if [[ -n $AUDIT_DB_URL ]]; then
    sed -e '/xasecure.audit.is.enabled/ { n; s/false/true/ }' -e '/xasecure.audit.db.is.enabled/ { n; s/false/true/ }' -i /etc/hive/conf/ranger-hive-audit.xml
    sed "s/AUDIT_DB_URL/${AUDIT_DB_URL}/" -i /etc/hive/conf/ranger-hive-audit.xml
    sed "s/AUDIT_DB_USER/$(vault read -field=username ${vault_path}/audit_db_user)/" -i /etc/hive/conf/ranger-hive-audit.xml
    sed "s/AUDIT_DB_PASSWORD/$(vault read -field=password ${vault_path}/audit_db_user)/" -i /etc/hive/conf/ranger-hive-audit.xml
fi

#check if database is initialized, test only from rw instances and only if DB is managed by apiary
if [ -z $EXTERNAL_DATABASE ] && [ x"$instance_type" = x"readwrite" ]; then
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
            aws --region=${AWS_REGION} glue create-database --database-input Name=${GLUE_PREFIX}${HIVE_DB},LocationUri=s3://${BUCKET_NAME}/ &> /dev/null
            aws --region=${AWS_REGION} glue update-database --name=${GLUE_PREFIX}${HIVE_DB} --database-input "Name=${GLUE_PREFIX}${HIVE_DB},LocationUri=s3://${BUCKET_NAME}/,Description=Managed by ${INSTANCE_NAME} datalake."
        fi
    done
fi
fi

[[ -z $loglevel ]] && loglevel="INFO"

[[ ! -z $SNS_ARN ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},com.expedia.apiary.extensions.metastore.listener.ApiarySnsListener"
[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},com.expedia.apiary.extensions.gluesync.listener.ApiaryGlueSync"
#remove leading , when external METASTORE_LISTENERS are not defined
export METASTORE_LISTENERS=$(echo $METASTORE_LISTENERS|sed 's/^,//')
sed "s/METASTORE_LISTENERS/${METASTORE_LISTENERS}/" -i /etc/hive/conf/hive-site.xml

[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expedia.apiary.extensions.gluesync.listener.ApiaryGluePreEventListener"
export METASTORE_PRELISTENERS=$(echo $METASTORE_PRELISTENERS|sed 's/^,//')
sed "s/METASTORE_PRELISTENERS/${METASTORE_PRELISTENERS}/" -i /etc/hive/conf/hive-site.xml

#required to debug ranger plugin, todo: send apache common logs to cloudwatch
#export HADOOP_OPTS="$HADOOP_OPTS -Dorg.apache.commons.logging.LogFactory=org.apache.commons.logging.impl.LogFactoryImpl -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.SimpleLog"

export AUX_CLASSPATH="/usr/share/java/mariadb-connector-java.jar"
[[ ! -z $SNS_ARN ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-metastore-listener-${APIARY_METASTORE_LISTENER_VERSION}-all.jar"
[[ ! -z $ENABLE_GLUESYNC ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar"
[[ ! -z $POLICY_MGR_URL ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar"

su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf hive.root.logger=${loglevel},console --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${dbhost}:3306/${dbname} --hiveconf javax.jdo.option.ConnectionUserName='${dbuser}' --hiveconf javax.jdo.option.ConnectionPassword='${dbpass}'"
