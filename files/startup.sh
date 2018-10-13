#!/bin/sh
# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

if [[ -n $VAULT_ADDR ]]; then
    export VAULT_SKIP_VERIFY=true
    export VAULT_TOKEN=`vault login -method=aws -path=${VAULT_LOGIN_PATH} -token-only`
fi

MYSQL_DB_USERNAME=`aws secretsmanager get-secret-value --secret-id ${MYSQL_SECRET_ARN}|jq .SecretString -r|jq .username -r`
MYSQL_DB_PASSWORD=`aws secretsmanager get-secret-value --secret-id ${MYSQL_SECRET_ARN}|jq .SecretString -r|jq .password -r`

#configure LDAP group mapping, required for ranger authorization
if [[ -n $LDAP_URL ]] ; then
    update_property.py hadoop.security.group.mapping.ldap.bind.user "$(vault read -field=bind_user ${VAULT_PATH}/ldap_user)" /etc/hadoop/conf/core-site.xml
    vault read -field=bind_password ${VAULT_PATH}/ldap_user > /etc/hadoop/conf/ldap-password.txt
    update_property.py hadoop.security.group.mapping org.apache.hadoop.security.LdapGroupsMapping /etc/hadoop/conf/core-site.xml
    update_property.py hadoop.security.group.mapping.ldap.url "${LDAP_URL}" /etc/hadoop/conf/core-site.xml
    update_property.py hadoop.security.group.mapping.ldap.base "${LDAP_BASE}" /etc/hadoop/conf/core-site.xml
    #configure local ca certificate to connect o ldap/ad
    vault read -field=cacert ${VAULT_PATH}/ldap_user > /etc/pki/ca-trust/source/anchors/ldapca.crt
    update-ca-trust
    update-ca-trust enable
fi

#configure ranger authorization
if [[ -n $RANGER_POLICY_MANAGER_URL ]]; then
    export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expedia.apiary.extensions.rangerauth.listener.ApiaryRangerAuthPreEventListener"
    update_property.py ranger.plugin.hive.policy.rest.url ${RANGER_POLICY_MANAGER_URL} /etc/hive/conf/ranger-hive-security.xml
    update_property.py ranger.plugin.hive.service.name ${RANGER_SERVICE_NAME} /etc/hive/conf/ranger-hive-security.xml
fi
#enable ranger auditing
if [[ -n $RANGER_AUDIT_SOLR_URL ]]; then
    update_property.py xasecure.audit.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.solr.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.solr.solr_url ${RANGER_AUDIT_SOLR_URL} /etc/hive/conf/ranger-hive-audit.xml
fi
#enable ranger db auditing
if [[ -n $RANGER_AUDIT_DB_URL ]]; then
    update_property.py xasecure.audit.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.db.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.url ${RANGER_AUDIT_DB_URL} /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.user "$(vault read -field=username ${VAULT_PATH}/audit_db_user)" /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.password "$(vault read -field=password ${VAULT_PATH}/audit_db_user)" /etc/hive/conf/ranger-hive-audit.xml
fi

if [ ! -z $ENABLE_METRICS ]; then
    export ECS_TASK_ID=$(wget -q -O - http://169.254.170.2/v2/metadata|jq -r .TaskARN|awk -F/ '{ print $NF }')
    export CLOUDWATCH_NAMESPACE="${INSTANCE_NAME}-metastore"
    update_property.py hive.metastore.metrics.enabled true /etc/hive/conf/hive-site.xml
fi

#check if database is initialized, test only from rw instances and only if DB is managed by apiary
if [ -z $EXTERNAL_DATABASE ] && [ x"$HIVE_METASTORE_ACCESS_MODE" = x"readwrite" ]; then
MYSQL_OPTIONS="-h$MYSQL_DB_HOST -u$MYSQL_DB_USERNAME -p$MYSQL_DB_PASSWORD $MYSQL_DB_NAME -N"
schema_version=`echo "select SCHEMA_VERSION from VERSION"|mysql $MYSQL_OPTIONS`
if [ x"$schema_version" != x"2.3.0" ]; then
    cd /usr/lib/hive/scripts/metastore/upgrade/mysql
    cat hive-schema-2.3.0.mysql.sql|mysql $MYSQL_OPTIONS
    cd /
fi

#create hive databases
if [ ! -z $HIVE_DB_NAMES ]; then
    for HIVE_DB in `echo $HIVE_DB_NAMES|tr "," "\n"`
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

[[ -z $HIVE_METASTORE_LOG_LEVEL ]] && HIVE_METASTORE_LOG_LEVEL="INFO"

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
[[ ! -z $RANGER_POLICY_MANAGER_URL ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar"
[[ ! -z $ENABLE_METRICS ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar"

su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf hive.root.logger=${HIVE_METASTORE_LOG_LEVEL},console --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${MYSQL_DB_HOST}:3306/${MYSQL_DB_NAME} --hiveconf javax.jdo.option.ConnectionUserName='${MYSQL_DB_USERNAME}' --hiveconf javax.jdo.option.ConnectionPassword='${MYSQL_DB_PASSWORD}'"
