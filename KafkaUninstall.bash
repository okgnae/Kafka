systemctl stop kafka
systemctl disable kafka
rm -rf /etc/systemd/system/kafka.service
 
userdel -r kafka
 
firewall-cmd --permanent --remove-rich-rule 'rule family="ipv4" source address="10.0.0.0/24" port port="9093" protocol="tcp" accept'
firewall-cmd  --reload
firewall-cmd  --list-all
