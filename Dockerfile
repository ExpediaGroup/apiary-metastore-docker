# Copyright (C) 2018 Expedia Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

from amazonlinux:latest
COPY files/RPM-GPG-KEY-emr /etc/pki/rpm-gpg/RPM-GPG-KEY-emr
COPY files/emr-bigtop.repo /etc/yum.repos.d/emr-bigtop.repo
COPY files/emr-platform.repo /etc/yum.repos.d/emr-platform.repo
RUN yum -v -y install java-1.8.0-openjdk
RUN yum -y install hive-metastore mariadb-connector-java
RUN ln -s /usr/share/java/mariadb-connector-java.jar /usr/lib/hive/lib/mariadb-connector-java.jar
RUN yum -y install emrfs
RUN echo 'export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*"' >> /etc/hadoop/conf/hadoop-env.sh
RUN yum -y install mysql wget unzip
RUN cd /tmp && wget -qN https://releases.hashicorp.com/vault/0.8.3/vault_0.8.3_linux_amd64.zip && unzip -q -o vault_0.8.3_linux_amd64.zip -d /usr/local/bin/ && rm -f vault_0.8.3_linux_amd64.zip
RUN mkdir -p /opt/hive-metastore-metrics/metrics
COPY files/core-site.xml /etc/hadoop/conf/core-site.xml
COPY files/emrfs-site.xml /usr/share/aws/emr/emrfs/conf/emrfs-site.xml
COPY files/hive-site.xml /etc/hive/conf/hive-site.xml
EXPOSE 9083
COPY files/startup.sh /startup.sh
CMD /startup.sh
