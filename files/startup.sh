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

# If Atlas metastore plugin is being used, set Atlas config properties
if [[ ! -z $ATLAS_KAFKA_BOOTSTRAP_SERVERS ]]
then
    # Update Atlas kafka URL
    sed "s/ATLAS_KAFKA_BOOTSTRAP_SERVERS/$ATLAS_KAFKA_BOOTSTRAP_SERVERS/" -i /etc/hive/conf/atlas-application.properties
    # Update Atlas cluster name
    # For backward compatability, if ATLAS_CLUSTER_NAME env var is not set, use INSTANCE_NAME
    [[ -z ${ATLAS_CLUSTER_NAME} ]] && ATLAS_CLUSTER_NAME=${INSTANCE_NAME}
    sed "s/ATLAS_CLUSTER_NAME/${ATLAS_CLUSTER_NAME}/g" -i /etc/hive/conf/atlas-application.properties
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
