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
import org.json.JSONObject;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hive.metastore.MetaStoreEventListener;
import org.apache.hadoop.hive.metastore.api.MetaException;
import org.apache.hadoop.hive.metastore.api.Table;
import org.apache.hadoop.hive.metastore.api.Partition;
import org.apache.hadoop.hive.metastore.events.*;

import com.amazonaws.services.sns.AmazonSNSClient;
import com.amazonaws.regions.Region;
import com.amazonaws.regions.RegionUtils;
import com.amazonaws.services.sns.model.PublishRequest;
import com.amazonaws.services.sns.model.PublishResult;


public class ApiarySNSListener extends MetaStoreEventListener  {
    private static final String topicArn = System.getenv("SNS_ARN");
    private static AmazonSNSClient snsClient;

    public ApiarySNSListener(Configuration config) {
        super(config);
        System.out.println(" ApiarySNSListener created ");

        //create a new SNS client and set endpoint
        snsClient = new AmazonSNSClient();
        snsClient.setRegion(RegionUtils.getRegion(System.getenv("AWS_REGION")));

    }

    @Override
    public void onCreateTable(CreateTableEvent event) throws MetaException {
	publishEvent("CREATE_TABLE",event.getTable(),null,null,null);
    }

    @Override
    public void onDropTable(DropTableEvent event) throws MetaException {
	publishEvent("DROP_TABLE",event.getTable(),null,null,null);
    }

    @Override
    public void onAlterTable(AlterTableEvent event) throws MetaException {
	publishEvent("ALTER_TABLE",event.getNewTable(),event.getOldTable(),null,null);
    }

    @Override
    public void onAddPartition(AddPartitionEvent event) throws MetaException {
	Iterator<Partition> partitions = event.getPartitionIterator();
        while(partitions.hasNext())
        {
            publishEvent("ADD_PARTITION",event.getTable(),null,partitions.next(),null);
        }
    }

    @Override
    public void onDropPartition(DropPartitionEvent event) throws MetaException {
	Iterator<Partition> partitions = event.getPartitionIterator();
        while(partitions.hasNext())
        {
	    publishEvent("DROP_PARTITION",event.getTable(),null,partitions.next(),null);
        }
    }

    @Override
    public void onAlterPartition(AlterPartitionEvent event) throws MetaException {
	publishEvent("ALTER_PARTITION",event.getTable(),null,event.getNewPartition(),event.getOldPartition());
    }

    void publishEvent(String event_type,Table table,Table oldtable,Partition partition,Partition oldpartition) throws MetaException {

	JSONObject json = new JSONObject();
	json.put("eventType",event_type);
	json.put("dbName",table.getDbName());
	json.put("tableName",table.getTableName());
	if(oldtable != null){
	    json.put("oldtableName",oldtable.getTableName());
	}
	if(partition != null){
	    json.put("Partition",partition.getValues());
	}
	if(oldpartition != null){
	    json.put("oldPartition",oldpartition.getValues());
	}
        String msg = json.toString();

        PublishRequest publishRequest = new PublishRequest(topicArn, msg);
        PublishResult publishResult = snsClient.publish(publishRequest);
        System.out.println("Published SNS Message - " + publishResult.getMessageId());
    }
}
