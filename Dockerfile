# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

FROM amazoncorretto:8

ENV RANGER_VERSION 2.0.0
ENV APIARY_EXTENSIONS_VERSION 8.0.2
ENV APIARY_GLUESYNC_LISTENER_VERSION 8.0.2
ENV APIARY_RANGER_PLUGIN_VERSION 5.0.1
ENV APIARY_METASTORE_METRICS_VERSION 4.2.0
ENV APIARY_METASTORE_AUTH_VERSION 4.2.0
ENV KAFKA_VERSION 2.3.1
ENV COMMONS_CODEC_VERSION 1.12
ENV GETHOSTNAME4J_VERSION 0.0.3
ENV JNA_VERSION 3.0.9
ENV EXPORTER_VERSION 0.12.0

COPY files/repoPublicKey.txt /var/aws/emr/repoPublicKey.txt
COPY files/emr-apps.repo /etc/yum.repos.d/emr-apps.repo
COPY files/emr-platform.repo /etc/yum.repos.d/emr-platform.repo
COPY files/emr-puppet.repo /etc/yum.repos.d/emr-puppet.repo

RUN yum -y install shadow-utils && \
    useradd -r hadoop
RUN yum -y install hive-metastore \
  mariadb-connector-java \
  mysql-connector-java \
  mysql \
  wget \
  zip \
  unzip \
  jq \
  tar \
  net-tools \
  && yum clean all \
  && rm -rf /var/cache/yum

RUN mkdir -p /usr/lib/apiary && cd /usr/lib/apiary && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-listener/${APIARY_EXTENSIONS_VERSION}/apiary-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar -O apiary-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/kafka-metastore-listener/${APIARY_EXTENSIONS_VERSION}/kafka-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar -O kafka-metastore-listener-${APIARY_EXTENSIONS_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-gluesync-listener/${APIARY_GLUESYNC_LISTENER_VERSION}/apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar -O apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-ranger-metastore-plugin/${APIARY_RANGER_PLUGIN_VERSION}/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar -O apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-metrics/${APIARY_METASTORE_METRICS_VERSION}/apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar -O apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-auth/${APIARY_METASTORE_AUTH_VERSION}/apiary-metastore-auth-${APIARY_METASTORE_AUTH_VERSION}.jar -O apiary-metastore-auth-${APIARY_METASTORE_AUTH_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=org/apache/kafka/kafka-clients/${KAFKA_VERSION}/kafka-clients-${KAFKA_VERSION}.jar -O kafka-clients-${KAFKA_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=commons-codec/commons-codec/${COMMONS_CODEC_VERSION}/commons-codec-${COMMONS_CODEC_VERSION}.jar -O commons-codec-${COMMONS_CODEC_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/kstruct/gethostname4j/${GETHOSTNAME4J_VERSION}/gethostname4j-${GETHOSTNAME4J_VERSION}.jar -O gethostname4j-${GETHOSTNAME4J_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/sun/jna/jna/${JNA_VERSION}/jna-${JNA_VERSION}.jar -O jna-${JNA_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=io/prometheus/jmx/jmx_prometheus_javaagent/${EXPORTER_VERSION}/jmx_prometheus_javaagent-${EXPORTER_VERSION}.jar -O jmx_prometheus_javaagent-${EXPORTER_VERSION}.jar

ENV MAVEN_VERSION 3.9.4

RUN wget -q -O - https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -C /opt -xzf - && \
    ln -sf /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /bin/mvn

COPY files/core-site.xml /etc/hadoop/conf/core-site.xml
COPY files/hive-site.xml /etc/hive/conf/hive-site.xml
COPY files/hive-log4j2.properties /etc/hive/conf/hive-log4j2.properties
COPY files/ranger-hive-security.xml /etc/hive/conf/ranger-hive-security.xml
COPY files/ranger-hive-audit.xml /etc/hive/conf/ranger-hive-audit.xml
COPY files/jmx-exporter.yaml /etc/hive/conf/jmx-exporter.yaml


EXPOSE 9083
COPY files/update_property.py /bin/update_property.py
COPY files/s3inventory.tpl /s3inventory.tpl
COPY files/startup.sh /startup.sh
COPY files/s3_inventory_repair.sh /s3_inventory_repair.sh
COPY files/allow-grant.sh /allow-grant.sh
COPY files/db-iam-user.sh /db-iam-user.sh
COPY files/log4j2-security.sh /tmp/log4j2-security.sh

# Added script to find and remove vulnerable log4j2 classes in order to mitigate security issue (CVE-2021-44228).
RUN chmod +x /tmp/log4j2-security.sh && /tmp/log4j2-security.sh

CMD /startup.sh
