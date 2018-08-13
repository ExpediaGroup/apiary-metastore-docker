/**
 * Copyright (C) 2018 Expedia Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Date;

import org.apache.hadoop.security.UserGroupInformation;
import org.apache.hadoop.hive.shims.Utils;
import com.google.common.collect.Sets;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hive.metastore.MetaStorePreEventListener;
import org.apache.hadoop.hive.metastore.api.*;
import org.apache.hadoop.hive.metastore.events.*;

import org.apache.hadoop.hive.ql.metadata.HiveException;

import org.apache.hadoop.hive.metastore.IHMSHandler;
import org.apache.thrift.TException;
import org.apache.hadoop.hive.conf.HiveConf;
import org.apache.hadoop.hive.ql.session.SessionState;
import java.util.Properties;
import java.util.Map.Entry;

import org.apache.ranger.plugin.service.RangerBasePlugin;
import org.apache.ranger.plugin.audit.RangerDefaultAuditHandler;

import org.apache.ranger.plugin.policyengine.*;

import org.apache.hadoop.hive.ql.security.authorization.plugin.HiveOperationType;

enum HiveAccessType { NONE, CREATE, ALTER, DROP, INDEX, LOCK, SELECT, UPDATE, USE, READ, WRITE, ALL, ADMIN };


/**
 * A MetaStorePreEventListener to authorizie using ranger.
 */

public class ApiaryRangerAuthPreEventListener extends MetaStorePreEventListener {

  private static RangerBasePlugin plugin = null;

  public ApiaryRangerAuthPreEventListener(Configuration config) throws HiveException {
    super(config);
    System.out.println(" ApiaryRangerAuthPreEventListener created ");
    plugin = new RangerBasePlugin("hive","metastore");
    plugin.init();
    plugin.setClusterName(System.getenv("RANGER_SERVICE_NAME"));
    plugin.setResultProcessor(new RangerDefaultAuditHandler());
  }

  @Override
  public void onEvent(PreEventContext context) throws MetaException, NoSuchObjectException, InvalidOperationException {

    String user = null;
    Set<String> groups = null;

    try{
        UserGroupInformation ugi = Utils.getUGI();
        user = ugi.getUserName();
        groups = Sets.newHashSet(ugi.getGroupNames());
    }
    catch(Exception ex)
    {
        ex.printStackTrace();
        System.out.println(ex);
        throw new InvalidOperationException("unable to read username.");
    }

    String hoptName = null;
    HiveAccessType hact = null;
    Table table = null;
    Database db = null;
    String databaseName = null;
    String tableName = null;
    RangerAccessResourceImpl resource = new RangerAccessResourceImpl();

    switch (context.getEventType()) {
    case CREATE_TABLE:
      table = ((PreCreateTableEvent) context).getTable();
      hoptName = HiveOperationType.CREATETABLE.name();
      hact = HiveAccessType.CREATE;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case DROP_TABLE:
      table = ((PreDropTableEvent) context).getTable();
      hoptName = HiveOperationType.DROPTABLE.name();
      hact = HiveAccessType.DROP;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case ALTER_TABLE:
      table = ((PreAlterTableEvent) context).getOldTable();
      hoptName = "ALTERTABLE";
      hact = HiveAccessType.ALTER;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case READ_TABLE:
      table = ((PreReadTableEvent) context).getTable();
      hoptName = HiveOperationType.QUERY.name();
      hact = HiveAccessType.SELECT;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case ADD_PARTITION:
      table = ((PreAddPartitionEvent) context).getTable();
      hoptName = "ADDPARTITION";
      hact = HiveAccessType.ALTER;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case DROP_PARTITION:
      table = ((PreDropPartitionEvent) context).getTable();
      hoptName = "DROPPARTITION";
      hact = HiveAccessType.ALTER;
      resource.setValue("database",table.getDbName());
      resource.setValue("table",table.getTableName());
      break;
    case ALTER_PARTITION:
      databaseName = ((PreAlterPartitionEvent) context).getDbName();
      tableName = ((PreAlterPartitionEvent) context).getTableName();
      hact = HiveAccessType.ALTER;
      hoptName = "ALTERPARTITION";
      resource.setValue("database",databaseName);
      resource.setValue("table",tableName);
      break;
    case ADD_INDEX:
      databaseName = ((PreAddIndexEvent) context).getIndex().getDbName();
      tableName = ((PreAddIndexEvent) context).getIndex().getOrigTableName();
      hoptName = "ADDINDEX";
      hact = HiveAccessType.CREATE;
      resource.setValue("database",databaseName);
      resource.setValue("table",tableName);
      break;
    case DROP_INDEX:
      hoptName = "DROPINDEX";
      hact = HiveAccessType.DROP;
      databaseName = ((PreDropIndexEvent) context).getIndex().getDbName();
      tableName = ((PreDropIndexEvent) context).getIndex().getOrigTableName();
      resource.setValue("database",databaseName);
      resource.setValue("table",tableName);
      break;
    case ALTER_INDEX:
      hoptName = "ALTERINDEX";
      hact = HiveAccessType.ALTER;
      databaseName = ((PreAlterIndexEvent) context).getOldIndex().getDbName();
      tableName = ((PreAlterIndexEvent) context).getOldIndex().getOrigTableName();
      resource.setValue("database",databaseName);
      resource.setValue("table",tableName);
      break;
    case READ_DATABASE:
      db = ((PreReadDatabaseEvent) context).getDatabase();
      hoptName = HiveOperationType.QUERY.name();
      hact = HiveAccessType.SELECT;
      resource.setValue("database",db.getName());
      break;
    case CREATE_DATABASE:
      db = ((PreCreateDatabaseEvent) context).getDatabase();
      hoptName = HiveOperationType.CREATEDATABASE.name();
      hact = HiveAccessType.CREATE;
      resource.setValue("database",db.getName());
      break;
    case DROP_DATABASE:
      db = ((PreDropDatabaseEvent) context).getDatabase();
      hoptName = HiveOperationType.DROPDATABASE.name();
      hact = HiveAccessType.DROP;
      resource.setValue("database",db.getName());
      break;
    default:
      return;
    }

    resource.setServiceDef(plugin.getServiceDef());
    RangerAccessRequestImpl request = new RangerAccessRequestImpl(resource,hact.name().toLowerCase(),user,groups);
    request.setAccessTime(new Date());
    request.setAction(hoptName);
    request.setClusterName(System.getenv("RANGER_SERVICE_NAME"));

    RangerAccessResult result = plugin.isAccessAllowed(request);
    if(result == null)
    {
         throw new InvalidOperationException("Permission denied: unable to evaluate ranger policy");
    }
    if (!result.getIsAllowed()) {
         String path = resource.getAsString();
         throw new InvalidOperationException(String.format("Permission denied: user [%s] does not have [%s] privilege on [%s]", user, hact.name().toLowerCase(), path));
    }

  }

}
