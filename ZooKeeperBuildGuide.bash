### Set BROKER_ID to {1,2,3} depending on which Broker your working on
BROKER_ID=1

### Download Apache ZooKeeper to /tmp, Check the version, make sure the link is still valid, will update
### Will be working automated download of the current version later in a update guide
curl --url https://downloads.apache.org/zookeeper/zookeeper-3.5.8/apache-zookeeper-3.5.8-bin.tar.gz --output /tmp/apache-zookeeper-3.5.8-bin.tar.gz

### Install Java on the Server
yum install java -y

### Move Zookeeper tarball to /opt
mv -f /tmp/apache-zookeeper-3.5.8-bin.tar.gz /opt/

### Untar file
tar -zxf /opt/apache-zookeeper-3.5.8-bin.tar.gz -C /opt/

### Rename Zookeeper directory using mv
mv -f /opt/apache-zookeeper-3.5.8-bin /opt/zookeeper/

### Make zookeeper user (UID below 1000 non-interactive)
useradd -u 994 -M -U zookeeper -s /sbin/nologin

### Backup sample conf file
mv /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo_sample.cfg.bak

### Copy file
cp /opt/zookeeper/conf/zoo_sample.cfg.bak /opt/zookeeper/conf/zoo.cfg
 
### Specify brokers in cluster
echo "server.1=KAFKA0001.hq.corp:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
echo "server.2=KAFKA0002.hq.corp:2888:3888" >> /opt/zookeeper/conf/zoo.cfg
echo "server.3=KAFKA0003.hq.corp:2888:3888" >> /opt/zookeeper/conf/zoo.cfg

### Create /opt/zookeeper/dataDir
mkdir /opt/zookeeper/dataDir/

### Modify data storage directory
sed -i 's/^dataDir=.*/dataDir=\/opt\/zookeeper\/dataDir/'  /opt/zookeeper/conf/zoo.cfg

### Create myid file - Edit myid value to match the BROKER_ID
echo ${BROKER_ID} > /opt/zookeeper/dataDir/myid

### Make opt zookeeper log directory
mkdir /opt/zookeeper/logs
 
### Specify log4j.properties (/opt/zookeeper/conf/log4j.properties)
sed -i 's/^zookeeper.log.dir=.*/zookeeper.log.dir=\/opt\/zookeeper\/logs/'  /opt/zookeeper/conf/log4j.properties
 
### Set Java parameters
cat << EOF > /opt/zookeeper/conf/environment.conf
ZOOMAIN=-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false org.apache.zookeeper.server.quorum.QuorumPeerMain
LOG4J=-Dlog4j.configuration=file:///opt/zookeeper/conf/log4j.properties
JVMFLAGS="-Xmx2048m -Djute.maxbuffer=1000000000"
ZOOCFG=/opt/zookeeper/conf/zoo.cfg
EOF

### Configuring Firewall
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="3888" protocol="tcp" accept'

firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="3888" protocol="tcp" accept'

firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="3888" protocol="tcp" accept'

firewall-cmd --reload
firewall-cmd --list-all

### Create Zookeeper service unit
cat << EOF > /etc/systemd/system/zookeeper.service
[Unit]
Description=Zookeeper
Documentation=https://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
WorkingDirectory=/opt/zookeeper
User=zookeeper
Group=zookeeper
Type=forking
Restart=on-failure
ExecStart=/opt/zookeeper/bin/zkServer.sh start
ExecStop=/opt/zookeeper/bin/zkServer.sh stop
ExecReload=/opt/zookeeper/bin/zkServer.sh restart
TimeoutStartSec=10min

[Install]
WantedBy=multi-user.target
EOF

### Reload Service Unit
systemctl daemon-reload
 
### Change permissions for zookeeper
chown -R zookeeper:zookeeper /opt/zookeeper
chmod -R 700  /opt/zookeeper

### Enable ZOOKEEPER service
systemctl enable zookeeper

### Start ZOOKEEPER service
systemctl start zookeeper
 
### Status ZOOKEEPER service
systemctl status zookeeper
