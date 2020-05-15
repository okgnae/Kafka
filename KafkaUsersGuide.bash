### Versions 
### Scala - Kafka version
###  2.12 - 2.5
 
### Kafka jar files
ll /opt/kafka/lib/*.jar

########################
#### BASIC COMMANDS ####
########################

###  Create Kafka Topics
/opt/kafka/bin/kafka-topics.sh  --create --zookeeper 127.0.0.1:2181 --replication-factor 2 --partitions  6 --topic TEST_TOPIC

###  List Kafka Topics
/opt/kafka/bin/kafka-topics.sh  --list --zookeeper 127.0.0.1:2181

###  View Kafka replication status
/opt/kafka/bin/kafka-topics.sh  --zookeeper 127.0.0.1:2181 --describe
/opt/kafka/bin/kafka-topics.sh  --zookeeper 127.0.0.1:2181 --describe  --under-replicated-partitions

###  Delete Kafka Topics
/opt/kafka/bin/kafka-topics.sh  --delete --zookeeper 127.0.0.1:2181 --topic TEST_TOPIC

##############################
### Zookeeper CLI Commands ###
##############################

/opt/kafka/bin/zookeeper-shell.sh  127.0.0.1:2181
    ?
    ls /
    ls /brokers
    ls /brokers/topics
    deleteall /brokers/topics/RCCSWA_TEST_1
 
    ### Exit Zookeeper CLI
    (Ctrl+C)
 
###################
#### CONSUMERS ####
###################

### Create ssl.consumer.properties file
cat <<-EOF > /etc/kafka/ssl/ssl.consumer.properties
# Consumer IDs
client.id=test-consumer
group.id=test-consumer-group
 
# SSL Config
security.protocol=SSL
ssl.truststore.location=/opt/kafka/ssl/server.truststore.jks
ssl.truststore.password=${PASSWORD}
EOF

### Create Console Consumer
/opt/kafka/bin/kafka-console-consumer.sh  --bootstrap-server KAFKA000${BROKER_ID}.hq.corp:9093 --consumer.config /etc/kafka/ssl/ssl.consumer.properties  --topic TEST_TOPIC

### List Consumer Groups
/opt/kafka/bin/kafka-consumer-groups.sh  --bootstrap-server KAFKA000${BROKER_ID}.hq.corp:9093  --command-config  /etc/kafka/ssl/ssl.consumer.properties  --list

###  Check Consumer offset lag
/opt/kafka/bin/kafka-consumer-groups.sh  --bootstrap-server KAFKA000${BROKER_ID}.hq.corp:9093  --command-config /etc/kafka/ssl/ssl.consumer.properties  --describe  --group  test-consumer-group

###  Delete Consumer Group
/opt/kafka/bin/kafka-consumer-groups.sh  --zookeeper 127.0.0.1:2181 --delete --group  test-consumer-group
/opt/kafka/bin/kafka-consumer-groups.sh  --bootstrap-server KAFKA000${BROKER_ID}.hq.corp:9093  --command-config /etc/kafka/ssl/ssl.consumer.properties  --delete  --group  test-consumer-group
 
##################
#### PRODUCER ####
##################

### Create ssl.producer.properties file
cat <<-EOF > /etc/kafka/ssl/ssl.producer.properties
# Producer IDs
client.id=test-producer
 
# SSL Config
security.protocol=SSL
ssl.truststore.location=/opt/kafka/ssl/server.truststore.jks
ssl.truststore.password=${PASSWORD}
EOF

### Create Console Producer
/opt/kafka/bin/kafka-console-producer.sh --broker-list KAFKA000${BROKER_ID}.hq.corp:9093 --producer.config  /etc/kafka/ssl/ssl.producer.properties  --topic TEST_TOPIC

##################
#### TEST SSL ####
##################
 
# openssl s_client -connect KAFKA000${BROKER_ID}.hq.corp:9093
