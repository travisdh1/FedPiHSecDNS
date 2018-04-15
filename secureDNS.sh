!#/bin/bash

#Download CloudFlared
wget https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.rpm

#Install the Package
dnf -y localinstall ./cloudflared-stable-linux-amd64.rpm

#Create a standard user to run as
useradd -s /usr/sbin/nologin -r -M cloudflared

#Change the ownership:group of the executable
chown cloudflared:cloudflared /usr/local/bin/cloudflared

#Create the config file
cat > /etc/default/cloudflared <<EOF
# Commandline args for cloudflared
CLOUDFLARED_OPTS=--proxy-dns=true --proxy-dns-upstream https://1.1.1.1/dns-query --proxy-dns-upstream https://1.0.0.1/dns-query --proxy-dns-port 5053
EOF

#Change the ownership of the config file to the standard user
chown cloudflared:cloudflared /etc/default/cloudflared

#Create the system startup/shutdown file for systemctl in /lib/systemd/system/cloudflared.service
cat > /lib/systemd/system/cloudflared.service <<EOF
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared $CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

#Enable and start cloudflared
systemctl enable cloudflared
systemctl start cloudflared

#Remove the current DNS lookup servers
sed -i 's/server/#server/' /etc/dnsmasq.d/01-pihole.conf

#Add the new local DNS proxy
echo "server=127.0.0.1:5053" >> /etc/dnsmasq.d/01-pihole.conf

#Restart the PiHole service
systemctl restart pihole-FTL.service
