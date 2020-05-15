### Set BROKER_ID to {1,2,3} depending on which Broker your working on
### Passwords are set in lab, dont write passwords in scripts in production 
BROKER_ID=1
KAFKA_PASS=kafka123

### Download Kafka tarball from apache
curl --url https://downloads.apache.org/kafka/2.5.0/kafka_2.12-2.5.0.tgz --output /tmp/kafka_2.12-2.5.0.tgz

### Move kafka tgz file from tmp to opt
mv /tmp/kafka_2.12-2.5.0.tgz /opt

### Untar file
tar -zxf /opt/kafka_2.12-2.5.0.tgz -C /opt

### Rename Kafka directory name
mv  /opt/kafka_2.12-2.5.0  /opt/kafka

### Create Data directory
mkdir /opt/kafka/data

### Make SSL Directory
mkdir /opt/kafka/ssl

### Add user. Will cause warning
useradd -u 996 -U kafka -m -d /opt/kafka -s /sbin/nologin

### Create Kafka service unit
cat << EOF > /etc/systemd/system/kafka.service
[Unit]
Description=Kafka
Documentation=http://kafka.apache.org
After=zookeeper.service
Requires=zookeeper.service

[Service]
SuccessExitStatus=143
WorkingDirectory=/opt/kafka
User=kafka
Type=simple
ExecStart=/opt/kafka/bin/kafka-server-start.sh  /opt/kafka/config/server.properties

[Install]
WantedBy=multi-user.target
EOF

### Reload Systemd Service units
systemctl daemon-reload

### Increase max java heap to 3GB (change as needed) in /opt/kafka/bin/kafka-server-start.sh
sed -i 's/ export KAFKA_HEAP_OPTS=.*/ export KAFKA_HEAP_OPTS="-Xmx1G -Xms1G"/' /opt/kafka/bin/kafka-server-start.sh

### Server.properties file Configurations
sed -i "s/^broker.id=.*/broker.id=${BROKER_ID}/"  /opt/kafka/config/server.properties
sed -i 's/^.*delete.topic.enable=.*/delete.topic.enable=true/'  /opt/kafka/config/server.properties
sed -i "s/^.*listeners=.*/listeners=SSL:\/\/KAFKA000${BROKER_ID}.hq.corp:9093/"  /opt/kafka/config/server.properties
sed -i "s/^.*advertised.listeners=.*/advertised.listeners=SSL:\/\/KAFKA000${BROKER_ID}.hq.corp:9093/"  /opt/kafka/config/server.properties
sed -i 's/^num.network.threads=.*/num.network.threads=6/'  /opt/kafka/config/server.properties
sed -i 's/^num.io.threads=.*/num.io.threads=10/'  /opt/kafka/config/server.properties
sed -i 's/^log.dirs=.*/log.dirs=\/opt\/kafka\/data/'  /opt/kafka/config/server.properties
sed -i 's/^num.partitions=.*/num.partitions=6/'  /opt/kafka/config/server.properties
sed -i 's/^log.retention.hours=.*/log.retention.hours=12/'  /opt/kafka/config/server.properties
sed -i 's/^zookeeper.connect=.*/zookeeper.connect=KAFKA0001.hq.corp:2181,KAFKA0002.hq.corp:2181,KAFKA0003.hq.corp:2181/'  /opt/kafka/config/server.properties

### SSL Configs for /opt/kafka/config/server.properties, you will have to fill in PASSWORD
cat << EOF >> /opt/kafka/config/server.properties

############################# SSL CONFIGS #############################

security.enabled.protocols=TLSv1.2
security.inter.broker.protocol=SSL
ssl.key.password=${KAFKA_PASS}
ssl.keystore.type=JKS
ssl.keystore.location=/opt/kafka/ssl/server.keystore.jks
ssl.keystore.password=${KAFKA_PASS}
ssl.truststore.type=JKS
ssl.truststore.location=/opt/kafka/ssl/server.truststore.jks
ssl.truststore.password=${KAFKA_PASS}
ssl.client.auth=none
EOF

### More Configs for /opt/kafka/config/server.properties
cat << EOF >> /opt/kafka/config/server.properties

############################# CONFIGS #############################

auto.create.topics.enable=false
compression.type=snappy
auto.leader.rebalance.enable=true
message.max.bytes=15728640
offsets.retention.minutes=1044
log.cleanup.policy=compact
max.partition.fetch.bytes=548576
fetch.max.bytes=15728640
replica.fetch.wait.max.ms=5000
EOF

### Make /etc/kafka/ssl 
mkdir /etc/kafka
mkdir /etc/kafka/ssl

#######################################################################################
###### Use this following setion if you dont alreay have a Certificate Authority ######
#######################################################################################
### This is only done on broker 1. All other certs need to be signed by broker 1 CA ###
#######################################################################################

### CA Passphrase for the this lab will be "ca123"
### Make a CA directory
mkdir /etc/kafka/ca

### Create Root CA Key
openssl ecparam -genkey -name secp384r1 | openssl ec -aes256 -out /etc/kafka/ca/kafka-root-ca-1.key

### Create and view Root CA Certificate
openssl req -x509 -days 3650 -extensions v3_ca -key /etc/kafka/ca/kafka-root-ca-1.key -out /etc/kafka/ca/kafka-root-ca-1.crt -subj "/O=corp/OU=hq/CN=kafka-root-ca-1"
openssl x509 -noout -text -in /etc/kafka/ca/kafka-root-ca-1.crt

### Create Root CA Serial file
echo 00 > /etc/kafka/ca/kafka-root-ca-1.srl

### Create intermediate CA Key
openssl ecparam -genkey -name secp384r1 | openssl ec -aes256 -out /etc/kafka/ca/kafka-interm-ca-1.key

### Create Intermediate CA CSR from Intermediate CA Key
openssl req -new -key /etc/kafka/ca/kafka-interm-ca-1.key -out /etc/kafka/ca/kafka-interm-ca-1.csr -subj "/O=corp/OU=hq/CN=kafka-interm-ca-1"
openssl req -text -noout -verify -in /etc/kafka/ca/kafka-interm-ca-1.csr

### Sign Intermediate CA CSR with root CA Key
openssl x509 -req -days 3650 -CA /etc/kafka/ca/kafka-root-ca-1.crt -CAkey /etc/kafka/ca/kafka-root-ca-1.key -CAserial /etc/kafka/ca/kafka-root-ca-1.srl -extensions v3_intermediate_ca -in /etc/kafka/ca/kafka-interm-ca-1.csr -out /etc/kafka/ca/kafka-interm-ca-1.crt
openssl x509 -noout -text -in /etc/kafka/ca/kafka-interm-ca-1.cer

### Create Root CA Serial file
echo 00 > /etc/kafka/ca/kafka-interm-ca-1.srl

### Sign CSRs with the intermediate CA, you will have to make you CSRs on each broker
### openssl x509 -req -days 3650 -CA /etc/kafka/ca/kafka-interm-ca-1.cer -CAkey /etc/kafka/ca/kafka-interm-ca-1.key -CAserial /etc/kafka/ca/kafka-interm-ca-1.srl -in /etc/kafka/ca/${BROKER_CSR} -out /etc/kafka/ca/${BROKER_CER}

################################################################
### If you created a CA on Broker1 one you will need to copy ###
####### all other brokers CSRs there to have them signed #######
################################################################

### Create Kafka Brokers Private Key and CSR
openssl req -nodes -newkey rsa:2048 -keyout /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.key  -out /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.csr -subj "/C=US/O=corp/OU=hq/CN=KAFKA000${BROKER_ID}.hq.corp"

##################################################################
### If you have a third party CA have it sign the Broker Certs ###
### If not then sign the Broker CSR with the kafka-interm-ca-1 ###
##################################################################

### sign the Broker CSR with kafka-interm-ca-1
openssl x509 -req -days 3650 -CA /etc/kafka/ca/kafka-interm-ca-1.crt -CAkey /etc/kafka/ca/kafka-interm-ca-1.key -CAserial /etc/kafka/ca/kafka-interm-ca-1.srl -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.csr -out /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.crt

### Check keys, CSRs and certs
openssl req -text -noout -verify -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.csr
openssl rsa -check -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.key
openssl x509 -noout -text -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.cer

### Combine Server .key and the Server .cer files to create the server .p12. Use same passwords as set in SSL CONFIGS section of the sever.properties file
openssl pkcs12 -export -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.crt -inkey /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.key -name KAFKA000${BROKER_ID}.hq.corp.p12 -out /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.p12
openssl pkcs12 -info -in /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.p12

### Create Server Key Store and add certs. Use same passwords as set in SSL CONFIGS section of the sever.properties file
keytool -importkeystore -srckeystore /etc/kafka/ssl/KAFKA000${BROKER_ID}.hq.corp.p12 -destkeystore /opt/kafka/ssl/server.keystore.jks -srcstoretype pkcs12 -alias KAFKA000${BROKER_ID}.hq.corp.p12
keytool -keystore /opt/kafka/ssl/server.keystore.jks -alias kafka-root-ca-1 -import -file "/etc/kafka/ca/kafka-root-ca-1.crt"
keytool -keystore /opt/kafka/ssl/server.keystore.jks -alias kafka-interm-ca-1 -import -file "/etc/kafka/ca/kafka-interm-ca-1.crt"

### Create Server Trust Store and add CA Root Cert. Use same passwords as set in SSL CONFIGS section of the sever.properties file
keytool -keystore /opt/kafka/ssl/server.truststore.jks -alias kafka-root-ca 1 -import -file "/etc/kafka/ca/kafka-root-ca-1.crt"
keytool -keystore /opt/kafka/ssl/server.truststore.jks -alias kafka-interm-ca-1 -import -file "/etc/kafka/ca/kafka-interm-ca-1.crt"

### Create Client Trust Store and add CA certs. Use same passwords as set in SSL CONFIGS section of the sever.properties file
keytool -keystore /opt/kafka/ssl/client.truststore.jks -alias kafka-root-ca-1 -import -file "/etc/kafka/ca/kafka-root-ca-1.crt"
keytool -keystore /opt/kafka/ssl/client.truststore.jks -alias kafka-interm-ca-1 -import -file "/etc/kafka/ca/kafka-interm-ca-1.crt"

### List certs in stores to validate
keytool -list -keystore /opt/kafka/ssl/server.keystore.jks
keytool -list -keystore /opt/kafka/ssl/server.truststore.jks
keytool -list -keystore /opt/kafka/ssl/client.truststore.jks

### Backup Key Stores to /etc/kafka/ssl
cp  /opt/kafka/ssl/*.jks  /etc/kafka/ssl

### Correct Kafka directory permissions
chown -R kafka:kafka /opt/kafka
chmod -R 700 /opt/kafka
chown -R root:root  /etc/kafka
chmod -R 700 /etc/kafka

### Configuring Firewall
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.0/24" port port="9093" protocol="tcp" accept'
firewall-cmd --reload
firewall-cmd --list-all

### Set Kafka Service to start on boot
systemctl enable kafka

### Start Kafka Service
systemctl start kafka

### Status Kafka Service
systemctl  status  kafka
