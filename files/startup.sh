#!/bin/bash
# Copyright (C) 2018-2020 Expedia, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");

set -x


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
