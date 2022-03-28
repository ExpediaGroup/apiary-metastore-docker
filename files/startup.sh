#!/bin/bash
# Copyright (C) 2018-2020 Expedia, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

set -x

[[ -z "$MYSQL_DB_USERNAME" ]] && export MYSQL_DB_USERNAME=$(aws secretsmanager get-secret-value --secret-id ${MYSQL_SECRET_ARN}|jq .SecretString -r|jq .username -r)
[[ -z "$MYSQL_DB_PASSWORD" ]] && export MYSQL_DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id ${MYSQL_SECRET_ARN}|jq .SecretString -r|jq .password -r)


#config Hive min/max thread pool size.  Terraform will set the env var based on size of memory
if [[ -n ${HMS_MIN_THREADS} ]]; then
  update_property.py hive.metastore.server.min.threads "${HMS_MIN_THREADS}" /etc/hive/conf/hive-site.xml
fi
if [[ -n ${HMS_MAX_THREADS} ]]; then
  update_property.py hive.metastore.server.max.threads "${HMS_MAX_THREADS}" /etc/hive/conf/hive-site.xml
fi

if [[ -n ${DISALLOW_INCOMPATIBLE_COL_TYPE_CHANGES} ]]; then
  update_property.py hive.metastore.disallow.incompatible.col.type.changes "${DISALLOW_INCOMPATIBLE_COL_TYPE_CHANGES}" /etc/hive/conf/hive-site.xml
fi

#configure LDAP group mapping, required for ranger authorization
if [[ -n $LDAP_URL ]] ; then
    update_property.py hadoop.security.group.mapping.ldap.bind.user "$(aws secretsmanager get-secret-value --secret-id ${LDAP_SECRET_ARN}|jq .SecretString -r|jq .username -r)" /etc/hadoop/conf/core-site.xml
    aws secretsmanager get-secret-value --secret-id ${LDAP_SECRET_ARN}|jq .SecretString -r|jq .password -r > /etc/hadoop/conf/ldap-password.txt
    update_property.py hadoop.security.group.mapping org.apache.hadoop.security.LdapGroupsMapping /etc/hadoop/conf/core-site.xml
    update_property.py hadoop.security.group.mapping.ldap.url "${LDAP_URL}" /etc/hadoop/conf/core-site.xml
    update_property.py hadoop.security.group.mapping.ldap.base "${LDAP_BASE}" /etc/hadoop/conf/core-site.xml
    #configure local ca certificate to connect o ldap/ad
    echo ${LDAP_CA_CERT}|base64 -d > /etc/pki/ca-trust/source/anchors/ldapca.crt
    update-ca-trust
    update-ca-trust enable
fi

#configure ranger authorization
if [[ -n $RANGER_POLICY_MANAGER_URL ]]; then
    export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expediagroup.apiary.extensions.rangerauth.listener.ApiaryRangerAuthPreEventListener"
    update_property.py ranger.plugin.hive.policy.rest.url ${RANGER_POLICY_MANAGER_URL} /etc/hive/conf/ranger-hive-security.xml
    update_property.py ranger.plugin.hive.service.name ${RANGER_SERVICE_NAME} /etc/hive/conf/ranger-hive-security.xml
fi
#enable ranger auditing
if [[ -n $RANGER_AUDIT_SOLR_URL ]]; then
    update_property.py xasecure.audit.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.destination.solr true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.destination.solr.urls ${RANGER_AUDIT_SOLR_URL} /etc/hive/conf/ranger-hive-audit.xml
    if [ "$HIVE_METASTORE_ACCESS_MODE" = "readwrite" ]; then
        update_property.py ranger.plugin.hive.policy.source.impl "org.apache.ranger.admin.client.RangerAdminRESTClient" /etc/hive/conf/ranger-hive-security.xml
    elif [ "$HIVE_METASTORE_ACCESS_MODE" = "readonly" ]; then
        update_property.py ranger.plugin.hive.policy.source.impl "com.expediagroup.apiary.extensions.rangerauth.policyproviders.ApiaryRangerAuthAllAccessPolicyProvider" /etc/hive/conf/ranger-hive-security.xml
    fi
fi
#enable ranger db auditing
if [[ -n $RANGER_AUDIT_DB_URL ]]; then
    update_property.py xasecure.audit.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.db.is.enabled true /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.url ${RANGER_AUDIT_DB_URL} /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.user "$(aws secretsmanager get-secret-value --secret-id ${RANGER_AUDIT_SECRET_ARN}|jq .SecretString -r|jq .username -r)" /etc/hive/conf/ranger-hive-audit.xml
    update_property.py xasecure.audit.jpa.javax.persistence.jdbc.password "$(aws secretsmanager get-secret-value --secret-id ${RANGER_AUDIT_SECRET_ARN}|jq .SecretString -r|jq .password -r)" /etc/hive/conf/ranger-hive-audit.xml
    if [ "$HIVE_METASTORE_ACCESS_MODE" = "readwrite" ]; then
        update_property.py ranger.plugin.hive.policy.source.impl "org.apache.ranger.admin.client.RangerAdminRESTClient" /etc/hive/conf/ranger-hive-security.xml
    elif [ "$HIVE_METASTORE_ACCESS_MODE" = "readonly" ]; then
        update_property.py ranger.plugin.hive.policy.source.impl "com.expediagroup.apiary.extensions.rangerauth.policyproviders.ApiaryRangerAuthAllAccessPolicyProvider" /etc/hive/conf/ranger-hive-security.xml
    fi
fi

if [ -n "$ENABLE_METRICS" ]; then
    update_property.py hive.metastore.metrics.enabled true /etc/hive/conf/hive-site.xml
    #configure to send metrics to cloudwatch when running on ECS
    if [ -n "$ECS_CONTAINER_METADATA_URI" ]; then
        export CLOUDWATCH_NAMESPACE="${INSTANCE_NAME}-metastore"
        export ECS_TASK_ID=$(wget -q -O - ${ECS_CONTAINER_METADATA_URI}/task|jq -r .TaskARN|awk -F/ '{ print $NF }')
        update_property.py hive.service.metrics.class com.expediagroup.apiary.extensions.metastore.metrics.CodahaleMetrics /etc/hive/conf/hive-site.xml
    fi
    #enable prometheus jmx agent when running on kubernetes
    if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
        export EXPORTER_OPTS="-javaagent:/usr/lib/apiary/jmx_prometheus_javaagent-${EXPORTER_VERSION}.jar=8080:/etc/hive/conf/jmx-exporter.yaml"
    fi
fi

#configure kafka metastore listener
if [[ ! -z $KAFKA_BOOTSTRAP_SERVERS ]]; then
    sed "s/KAFKA_BOOTSTRAP_SERVERS/$KAFKA_BOOTSTRAP_SERVERS/" -i /etc/hive/conf/hive-site.xml
    sed "s/KAFKA_TOPIC_NAME/$KAFKA_TOPIC_NAME/" -i /etc/hive/conf/hive-site.xml
    [[ -n $ECS_CONTAINER_METADATA_URI ]] && export KAFKA_CLIENT_ID=$(wget -q -O - ${ECS_CONTAINER_METADATA_URI}/task|jq -r .TaskARN|awk -F/ '{ print $NF }')
    [[ -n $KUBERNETES_SERVICE_HOST ]] && export KAFKA_CLIENT_ID="$HOSTNAME"
    [[ -n $KAFKA_CLIENT_ID ]] && sed "s/KAFKA_CLIENT_ID/$KAFKA_CLIENT_ID/" -i /etc/hive/conf/hive-site.xml
fi

APIARY_S3_INVENTORY_SCHEMA=s3_inventory
APIARY_S3_LOGS_SCHEMA=s3_logs_hive

#check if database is initialized, test only from rw instances and only if DB is managed by apiary
if [ -z $EXTERNAL_DATABASE ] && [ "$HIVE_METASTORE_ACCESS_MODE" = "readwrite" ]; then
    MYSQL_OPTIONS="-h$MYSQL_DB_HOST -u$MYSQL_DB_USERNAME -p$MYSQL_DB_PASSWORD $MYSQL_DB_NAME -N"
    schema_version=`echo "select SCHEMA_VERSION from VERSION"|mysql $MYSQL_OPTIONS`
    if [ "$schema_version" != "2.3.0" ]; then
        cd /usr/lib/hive/scripts/metastore/upgrade/mysql
        cat hive-schema-2.3.0.mysql.sql|mysql $MYSQL_OPTIONS
        cd /
    fi

    #create hive databases
    if [ ! -z $HIVE_DB_NAMES ]; then
        if [ ! -z $ENABLE_S3_INVENTORY ]; then
            HIVE_APIARY_DB_NAMES="${HIVE_DB_NAMES},${APIARY_S3_INVENTORY_SCHEMA}"
        else
            HIVE_APIARY_DB_NAMES="${HIVE_DB_NAMES}"
        fi
        if [ ! -z $ENABLE_S3_LOGS ]; then
            HIVE_APIARY_DB_NAMES="${HIVE_APIARY_DB_NAMES},${APIARY_S3_LOGS_SCHEMA}"
        fi

        HIVE_APIARY_DB_NAMES="${HIVE_APIARY_DB_NAMES},${APIARY_SYSTEM_SCHEMA:-apiary_system}"

        AWS_ACCOUNT=`aws sts get-caller-identity|jq -r .Account`
        for HIVE_DB in `echo ${HIVE_APIARY_DB_NAMES}|tr "," "\n"`
        do
            echo "creating hive database $HIVE_DB"
            DB_ID=`echo "select MAX(DB_ID)+1 from DBS"|mysql $MYSQL_OPTIONS`
            BUCKET_NAME=$(echo "${INSTANCE_NAME}-${AWS_ACCOUNT}-${AWS_REGION}-${HIVE_DB}"|tr "_" "-")
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

#pre event listener to restrict hive database access in read-only metastores
[[ ! -z $HIVE_DB_WHITELIST ]] && export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expediagroup.apiary.extensions.readonlyauth.listener.ApiaryReadOnlyAuthPreEventListener"

[[ -z $HIVE_METASTORE_LOG_LEVEL ]] && HIVE_METASTORE_LOG_LEVEL="INFO"
sed "s/HIVE_METASTORE_LOG_LEVEL/$HIVE_METASTORE_LOG_LEVEL/" -i /etc/hive/conf/hive-log4j2.properties

[[ ! -z $SNS_ARN ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},com.expediagroup.apiary.extensions.events.metastore.listener.ApiarySnsListener"
[[ ! -z $KAFKA_BOOTSTRAP_SERVERS ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},com.expediagroup.apiary.extensions.events.metastore.kafka.listener.KafkaMetaStoreEventListener"
[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_LISTENERS="${METASTORE_LISTENERS},com.expediagroup.apiary.extensions.gluesync.listener.ApiaryGlueSync"
#remove leading , when external METASTORE_LISTENERS are not defined
export METASTORE_LISTENERS=$(echo $METASTORE_LISTENERS|sed 's/^,//')
sed "s/METASTORE_LISTENERS/${METASTORE_LISTENERS}/" -i /etc/hive/conf/hive-site.xml

[[ ! -z $ENABLE_GLUESYNC ]] && export METASTORE_PRELISTENERS="${METASTORE_PRELISTENERS},com.expediagroup.apiary.extensions.gluesync.listener.ApiaryGluePreEventListener"
export METASTORE_PRELISTENERS=$(echo $METASTORE_PRELISTENERS|sed 's/^,//')
sed "s/METASTORE_PRELISTENERS/${METASTORE_PRELISTENERS}/" -i /etc/hive/conf/hive-site.xml

#required to debug ranger plugin, todo: send apache common logs to cloudwatch
#export HADOOP_OPTS="$HADOOP_OPTS -Dorg.apache.commons.logging.LogFactory=org.apache.commons.logging.impl.LogFactoryImpl -Dorg.apache.commons.logging.Log=org.apache.commons.logging.impl.SimpleLog"

export AUX_CLASSPATH="/usr/share/java/mariadb-connector-java.jar"
[[ ! -z $SNS_ARN ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar"
[[ ! -z $KAFKA_BOOTSTRAP_SERVERS ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/kafka-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar:/usr/lib/apiary/kafka-clients-${KAFKA_VERSION}.jar"
[[ ! -z $ENABLE_GLUESYNC ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar"
[[ ! -z $RANGER_POLICY_MANAGER_URL ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar:/usr/lib/apiary/commons-codec-${COMMONS_CODEC_VERSION}.jar:/usr/lib/apiary/gethostname4j-${GETHOSTNAME4J_VERSION}.jar:/usr/lib/apiary/jna-${JNA_VERSION}.jar"
[[ ! -z $HIVE_DB_WHITELIST ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-metastore-auth-${APIARY_METASTORE_AUTH_VERSION}.jar"
[[ ! -z $ENABLE_METRICS ]] && export AUX_CLASSPATH="$AUX_CLASSPATH:/usr/lib/apiary/apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar"

#configure container credentials provider when running in ECS
if [ ! -z ${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI} ]; then
    update_property.py fs.s3a.aws.credentials.provider com.amazonaws.auth.ContainerCredentialsProvider /etc/hadoop/conf/core-site.xml
fi

#configure WebIdentityTokenCredentialsProvider when running with IRSA/OIDC
if [ ! -z ${AWS_WEB_IDENTITY_TOKEN_FILE} ]; then
    update_property.py fs.s3a.aws.credentials.provider com.amazonaws.auth.WebIdentityTokenCredentialsProvider /etc/hadoop/conf/core-site.xml
fi

#auto configure heapsize
if [ ! -z ${ECS_CONTAINER_METADATA_URI} ]; then
    export MEM_LIMIT=$(wget -q -O - ${ECS_CONTAINER_METADATA_URI}/task|jq -r .Limits.Memory)
    export HADOOP_HEAPSIZE=$(expr $MEM_LIMIT \* 90 / 100)
fi
[[ -z $HADOOP_HEAPSIZE ]] && export HADOOP_HEAPSIZE=1024

export HADOOP_OPTS="-XshowSettings:vm -Xms${HADOOP_HEAPSIZE}m $EXPORTER_OPTS"
su hive -s/bin/bash -c "/usr/lib/hive/bin/hive --service metastore --hiveconf javax.jdo.option.ConnectionURL=jdbc:mysql://${MYSQL_DB_HOST}:3306/${MYSQL_DB_NAME} --hiveconf javax.jdo.option.ConnectionUserName='${MYSQL_DB_USERNAME}' --hiveconf javax.jdo.option.ConnectionPassword='${MYSQL_DB_PASSWORD}'"
