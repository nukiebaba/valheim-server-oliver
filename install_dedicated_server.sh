#!/bin/bash

sudo yum update
sudo yum upgrade

yum install glibc.i686 libstdc++.i686
yum install nano
yum install nc

useradd -m steam
useradd -m valheim
groupadd valheimserver
usermod -a -G valheimserver valheim
usermod -a -G valheimserver steam


mkdir /opt/steam
mkdir /opt/steam/steamcmd
cd /opt/steam/steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
chown -R steam:steam /opt/steam

mkdir /opt/valheim
mkdir /var/log/valheim
chown valheim:valheim /opt/valheim
chown valheim:valheim /var/log/valheim

yum install lvm2*
pvcreate /dev/xvdb
vgcreate vg_valheim /dev/xvdb
lvcreate -l 100%FREE -n lv_valheim vg_valheim
mkfs -t xfs /dev/vg_valheim/lv_valheim

# Add to /etc/fstab
# vi /etc/fstab
/dev/vg_valheim/lv_valheim                /opt/valheim              xfs     defaults        0 0

mount /dev/vg_valheim/lv_valheim
mkdir /opt/valheim/valheimserver
chown -R valheim:valheimserver /opt/valheim
chmod 0750 /opt/valheim
chmod 0770 /opt/valheim/valheimserver

su valheim
sh /opt/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /opt/valheim/valheimserver +app_update 896660 validate +exit

#+login anonymous +app_info_print 896660

mkdir /opt/valheim/init
cp /opt/valheim/valheimserver/start_server.sh /opt/valheim/init/start_server.sh
chmod +x /opt/valheim/init/start_server.sh


# Init file
# Had to use nano for this
cat > /opt/valheim/init/start_server.sh <<EOF
#!/bin/bash
export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
# Tip: Make a local copy of this script to avoid it being overwritten by steam.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
./valheim_server.x86_64 -name OliverLand -port 2456 -nographics -batchmode -world "Golaptocar" -password lUZBGtILsA5Fffkf2CUS
export LD_LIBRARY_PATH=$templdpath
EOF


### Environment file
nano /etc/systemd/system/valheimserver.env

DisplayName=OliverLand
ServerPort=6969
WorldName=Golaptocar
ServerPassword=lUZBGtILsA5Fffkf2CUS
EOF

chmod 744 /etc/systemd/system/valheimserver.env


# Systemd Unit File

[Unit]
Description=Valheim Server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target
[Service]
Type=simple
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
User=valheim
Group=valheimserver
ExecStartPre=/opt/steam/steamcmd/steamcmd.sh +login anonymous +force_install_dir /opt/valheim/valheimserver +app_update 896660 validate +exit
ExecStart=/bin/bash /opt/valheim/init/start_server.sh
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGINT
WorkingDirectory=/opt/valheim/valheimserver
LimitNOFILE=100000
[Install]
WantedBy=multi-user.target








cat /etc/systemd/system/valheimserver.service
systemctl daemon-reload
journalctl -u valheimserver -f