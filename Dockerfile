# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

from amazonlinux:latest

ENV RANGER_VERSION 1.1.0
ENV APIARY_METASTORE_LISTENER_VERSION 4.2.0
ENV APIARY_GLUESYNC_LISTENER_VERSION 4.2.0
ENV APIARY_RANGER_PLUGIN_VERSION 4.2.0
ENV APIARY_METASTORE_METRICS_VERSION 4.2.0
ENV APIARY_METASTORE_AUTH_VERSION 4.2.0

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
  && yum clean all \
  && rm -rf /var/cache/yum

RUN mkdir -p /usr/lib/apiary && cd /usr/lib/apiary && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-listener/${APIARY_METASTORE_LISTENER_VERSION}/apiary-metastore-listener-${APIARY_METASTORE_LISTENER_VERSION}-all.jar -O apiary-metastore-listener-${APIARY_METASTORE_LISTENER_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-gluesync-listener/${APIARY_GLUESYNC_LISTENER_VERSION}/apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar -O apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-ranger-metastore-plugin/${APIARY_RANGER_PLUGIN_VERSION}/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar -O apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-metrics/${APIARY_METASTORE_METRICS_VERSION}/apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar -O apiary-metastore-metrics-${APIARY_METASTORE_METRICS_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expediagroup/apiary/apiary-metastore-auth/${APIARY_METASTORE_AUTH_VERSION}/apiary-metastore-auth-${APIARY_METASTORE_AUTH_VERSION}.jar -O apiary-metastore-auth-${APIARY_METASTORE_AUTH_VERSION}.jar

ENV ATLAS_VERSION 2.0.0
ENV MAVEN_VERSION 3.5.4

RUN wget -q -O - http://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz|tar -C /opt -xzf - && \
    ln -sf /opt/apache-maven-${MAVEN_VERSION}/bin/mvn /bin/mvn

COPY files/atlas-2.0.0-hive-2.3.3.patch /tmp/atlas-2.0.0-hive-2.3.3.patch
RUN cd /tmp && \
    wget https://www-us.apache.org/dist/atlas/${ATLAS_VERSION}/apache-atlas-${ATLAS_VERSION}-sources.tar.gz && \
    tar xvfz apache-atlas-${ATLAS_VERSION}-sources.tar.gz && \
    cd apache-atlas-sources-${ATLAS_VERSION}/ && \
    patch  -p1 < /tmp/atlas-2.0.0-hive-2.3.3.patch && \
    cd addons/hive-bridge && \
    mvn package -Dhive.version=2.3.3 && \
    cp -a target/hive-bridge-${ATLAS_VERSION}.jar /usr/lib/apiary/ && \
    cd /tmp && rm -rf /root/.m2 && rm -rf /tmp/apache-atlas-sources-${ATLAS_VERSION}/ && rm -f /tmp/apache-atlas-${ATLAS_VERSION}-sources.tar.gz

COPY files/core-site.xml /etc/hadoop/conf/core-site.xml
COPY files/hive-site.xml /etc/hive/conf/hive-site.xml
COPY files/hive-log4j2.properties /etc/hive/conf/hive-log4j2.properties
COPY files/ranger-hive-security.xml /etc/hive/conf/ranger-hive-security.xml
COPY files/ranger-hive-audit.xml /etc/hive/conf/ranger-hive-audit.xml
COPY files/atlas-application.properties /etc/hive/conf/atlas-application.properties


EXPOSE 9083
COPY files/update_property.py /bin/update_property.py
COPY files/startup.sh /startup.sh
CMD /startup.sh
