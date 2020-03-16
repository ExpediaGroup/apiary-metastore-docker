# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

from amazonlinux:latest

ENV RANGER_VERSION 2.0.0
ENV APIARY_EXTENSIONS_VERSION 6.0.0
ENV APIARY_GLUESYNC_LISTENER_VERSION 4.2.0
ENV APIARY_RANGER_PLUGIN_VERSION 5.0.1
ENV APIARY_METASTORE_METRICS_VERSION 4.2.0
ENV APIARY_METASTORE_AUTH_VERSION 4.2.0
ENV ATLAS_VERSION 2.0.0
ENV KAFKA_VERSION 2.3.1
ENV COMMONS_CODEC_VERSION 1.12
ENV GETHOSTNAME4J_VERSION 0.0.3
ENV JNA_VERSION 3.0.9
ENV EXPORTER_VERSION 0.12.0

COPY files/RPM-GPG-KEY-emr /etc/pki/rpm-gpg/RPM-GPG-KEY-emr
COPY files/emr-apps.repo /etc/yum.repos.d/emr-apps.repo
COPY files/emr-platform.repo /etc/yum.repos.d/emr-platform.repo

RUN yum -y install java-1.8.0-openjdk \
  java-1.8.0-openjdk-devel.x86_64 \
  hive-metastore \
  mariadb-connector-java \
  mysql \
  wget \
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
wget -q https://search.maven.org/remotecontent?filepath=org/apache/atlas/atlas-notification/${ATLAS_VERSION}/atlas-notification-${ATLAS_VERSION}.jar -O atlas-notification-${ATLAS_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=org/apache/atlas/atlas-intg/${ATLAS_VERSION}/atlas-intg-${ATLAS_VERSION}.jar -O atlas-intg-${ATLAS_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=org/apache/atlas/atlas-common/${ATLAS_VERSION}/atlas-common-${ATLAS_VERSION}.jar -O atlas-common-${ATLAS_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=org/apache/kafka/kafka-clients/${KAFKA_VERSION}/kafka-clients-${KAFKA_VERSION}.jar -O kafka-clients-${KAFKA_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=commons-codec/commons-codec/${COMMONS_CODEC_VERSION}/commons-codec-${COMMONS_CODEC_VERSION}.jar -O commons-codec-${COMMONS_CODEC_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/kstruct/gethostname4j/${GETHOSTNAME4J_VERSION}/gethostname4j-${GETHOSTNAME4J_VERSION}.jar -O gethostname4j-${GETHOSTNAME4J_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/sun/jna/jna/${JNA_VERSION}/jna-${JNA_VERSION}.jar -O jna-${JNA_VERSION}.jar && \
wget -q https://search.maven.org/remotecontent?filepath=io/prometheus/jmx/jmx_prometheus_javaagent/${EXPORTER_VERSION}/jmx_prometheus_javaagent-${EXPORTER_VERSION}.jar -O jmx_prometheus_javaagent-${EXPORTER_VERSION}.jar


ENV MAVEN_VERSION 3.6.3

RUN wget -q -O - http://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz|tar -C /opt -xzf - && \
    ln -sf /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /bin/mvn

COPY files/atlas-${ATLAS_VERSION}-hive-2.3.3.patch /tmp/atlas-${ATLAS_VERSION}-hive-2.3.3.patch
RUN cd /tmp && \
    wget -q https://www-us.apache.org/dist/atlas/${ATLAS_VERSION}/apache-atlas-${ATLAS_VERSION}-sources.tar.gz && \
    tar xfz apache-atlas-${ATLAS_VERSION}-sources.tar.gz && \
    cd apache-atlas-sources-${ATLAS_VERSION}/ && \
    patch  -p1 < /tmp/atlas-${ATLAS_VERSION}-hive-2.3.3.patch && \
    sed -s 's#http://repo1.maven.org#https://repo1.maven.org#' -i pom.xml && \
    cd addons/hive-bridge && mvn package -Dhive.version=2.3.3 && cp -a target/hive-bridge-${ATLAS_VERSION}.jar /usr/lib/apiary/ && \
    cd /tmp && rm -rf /root/.m2 && rm -rf /tmp/apache-atlas-sources-${ATLAS_VERSION}/ && rm -f /tmp/apache-atlas-${ATLAS_VERSION}-sources.tar.gz

COPY files/core-site.xml /etc/hadoop/conf/core-site.xml
COPY files/hive-site.xml /etc/hive/conf/hive-site.xml
COPY files/hive-log4j2.properties /etc/hive/conf/hive-log4j2.properties
COPY files/ranger-hive-security.xml /etc/hive/conf/ranger-hive-security.xml
COPY files/ranger-hive-audit.xml /etc/hive/conf/ranger-hive-audit.xml
COPY files/atlas-application.properties /etc/hive/conf/atlas-application.properties
COPY files/jmx-exporter.yaml /etc/hive/conf/jmx-exporter.yaml


EXPOSE 9083
COPY files/update_property.py /bin/update_property.py
COPY files/startup.sh /startup.sh
CMD /startup.sh
