### Linux Server Baseline
### You will need to set up baseline configurations for each server
### Configurations here is very for your environment

### Set up some accounts Accounts
# User: root
# Pass: 123

# User: user
# Pass: 123
 
### Filesystem
# xfs     /boot             1 GiB
# ext4    /                 10 GiB
# SWAP    [swap]            2 GiB
# ext4    /var              10 GiB
# ext4    /var/log/         10 GiB
# ext4    /var/log/audit    10 GiB
# ext4    /tmp              10 GiB
# ext4    /home             10 GiB
# ext4    /opt              Remaining

### Network ifcfg-enp0s3, this is just the way I set up my Oracle VBox Network, BROKER_ID should be {1,2,3} respective to the broker you are working on
vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
  TYPE=Ethernet
  PROXY_METHOD=none
  BROWSER_ONLY=no
  BOOTPROTO=none
  DEFROUTE=yes
  IPV4_FAILURE_FATAL=no
  IPV6INIT=no
  IPV6_AUTOCONF=no
  IPV6_DEFROUTE=no
  IPV6_FAILURE_FATAL=no
  IPV6_ADDR_GEN_MODE=stable-privacy
  NAME=enp0s3
  DEVICE=enp0s3
  ONBOOT=yes
  IPADDR=192.168.1.10${BROKER_ID}
  PREFIX=24
  GATEWAY=192.168.1.1

### Network ifcfg-enp0s8, this is just the way I set up my Oracle VBox Network
vi /etc/sysconfig/network-scripts/ifcfg-enp0s3
  TYPE=Ethernet
  PROXY_METHOD=none
  BROWSER_ONLY=no
  BOOTPROTO=none
  DEFROUTE=yes
  IPV4_FAILURE_FATAL=no
  IPV6INIT=no
  IPV6_AUTOCONF=no
  IPV6_DEFROUTE=no
  IPV6_FAILURE_FATAL=no
  IPV6_ADDR_GEN_MODE=stable-privacy
  NAME=enp0s8
  DEVICE=enp0s8
  ONBOOT=yes
  IPADDR=10.0.0.10${BROKER_ID}
  PREFIX=24
  GATEWAY=10.0.0.1

### Restart Network Service, Validate network configuration
systemctl restart network
systemctl status network
ip address

### Set Hostname based on BROKER_ID {1,2,3}
hostnamectl set-hostname KAFKA000${BROKER_ID}.hq.corp

### Configure /etc/hosts, add the following entries
vi /etc/hosts
  10.0.0.101      KAFKA0001.hq.corp
  10.0.0.102      KAFKA0002.hq.corp
  10.0.0.103      KAFKA0003.hq.corp

### Configure /etc/resolv.conf, make sure you update it for your nameserver
vi /etc/resolv.conf
  nameserver 10.0.0.11

### Create DNS A Record, From PowerShell as Domain Admin, You might have BIND, but this gives you the idea
# Add-DnsServerResourceRecordA  -Name KAFKA000${BROKER_ID} -AllowUpdateAny -CreatePtr -ZoneName '.hq.corp' -IPv4Address 10.0.0.10${BROKER_ID} -ComputerName (Get-ADDomainController).Name -Verbose
 

### Test resolving DNS Name and IP, From PowerShell, a nslookup is good to
# Resolve-DnsName KAFKA000${BROKER_ID} -Server (Get-ADDomainController).Name
# Resolve-DnsName 10.0.0.10KAFKA000${BROKER_ID} -Server (Get-ADDomainController).Name

### Configure firewallD SSH Rules
firewall-cmd --set-default=drop
firewall-cmd --remove-interface=enp0s3 --zone=public
firewall-cmd --add-interface=enp0s3 --zone=drop
firewall-cmd --remove-interface=enp0s8 --zone=public
firewall-cmd --add-interface=enp0s8 --zone=drop
firewall-cmd --permanent --add-rich-rule 'rule family="ipv4" source address="192.168.1.180" service name="ssh" accept'
firewall-cmd --reload
firewall-cmd --list-all

### Set up local yum repo
echo << EOF > /etc/yum.repos.d/CentOS-Local.repo
[CentOS-Local-Base]
name=CentOS-Local-Base
baseurl=http://10.0.0.10/yum/centos/base/Packages
gpgcheck=0
enabled=1

[CentOS-Local-Extras]
name=CentOS-Local-Extras
baseurl=http://10.0.0.10/yum/centos/extras/Packages
gpgcheck=0
enabled=1

[CentOS-Local-Updates]
name=CentOS-Local-Updates
baseurl=http://10.0.0.10/yum/centos/updates/Packages
gpgcheck=0
enabled=1
EOF

### Apply updates via YUM and reboot the server
yum update -y
reboot

### When the server is back online remove old kernels
yum remove kernel -y
