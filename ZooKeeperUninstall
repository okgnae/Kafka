systemctl stop zookeeper
systemctl disable zookeeper
rm -fr /etc/systemd/system/zookeeper.service
 
userdel -r zookeeper
 
rm -rf /opt/zookeeper
rm -rf /var/lib/zookeeper
rm -rf /var/log/zookeeper

firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.101" port port="3888" protocol="tcp" accept'
 
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.102" port port="3888" protocol="tcp" accept'
 
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="2181" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="2888" protocol="tcp" accept'
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.103" port port="3888" protocol="tcp" accept'
 
firewall-cmd --reload
firewall-cmd --list-all
