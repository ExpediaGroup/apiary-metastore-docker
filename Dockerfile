# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

from amazonlinux:latest

ENV VAULT_VERSION 0.10.3
ENV RANGER_VERSION 1.1.0
ENV APIARY_METASTORE_LISTENER_VERSION 0.1.0
ENV APIARY_GLUESYNC_LISTENER_VERSION 0.2.0
ENV APIARY_RANGER_PLUGIN_VERSION 0.2.0

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
  emrfs \
  && yum clean all \
  && rm -rf /var/cache/yum

RUN wget -qN https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && unzip -q -o vault_${VAULT_VERSION}_linux_amd64.zip -d /usr/local/bin/ && rm -f vault_${VAULT_VERSION}_linux_amd64.zip

RUN mkdir -p /usr/lib/apiary && cd /usr/lib/apiary && \
wget -q https://search.maven.org/remotecontent?filepath=com/expedia/apiary/apiary-metastore-listener/${APIARY_METASTORE_LISTENER_VERSION}/apiary-metastore-listener-${APIARY_METASTORE_LISTENER_VERSION}-all.jar -O apiary-metastore-listener-${APIARY_METASTORE_LISTENER_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expedia/apiary/apiary-gluesync-listener/${APIARY_GLUESYNC_LISTENER_VERSION}/apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar -O apiary-gluesync-listener-${APIARY_GLUESYNC_LISTENER_VERSION}-all.jar && \
wget -q https://search.maven.org/remotecontent?filepath=com/expedia/apiary/apiary-ranger-metastore-plugin/${APIARY_RANGER_PLUGIN_VERSION}/apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar -O apiary-ranger-metastore-plugin-${APIARY_RANGER_PLUGIN_VERSION}-all.jar

RUN echo 'export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*"' >> /etc/hadoop/conf/hadoop-env.sh
COPY files/core-site.xml /etc/hadoop/conf/core-site.xml
COPY files/emrfs-site.xml /usr/share/aws/emr/emrfs/conf/emrfs-site.xml
COPY files/hive-site.xml /etc/hive/conf/hive-site.xml
COPY files/ranger-hive-security.xml /etc/hive/conf/ranger-hive-security.xml
COPY files/ranger-hive-audit.xml /etc/hive/conf/ranger-hive-audit.xml

EXPOSE 9083
COPY files/startup.sh /startup.sh
CMD /startup.sh
