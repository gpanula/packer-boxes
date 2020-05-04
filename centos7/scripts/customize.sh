#!/bin/sh

# apply our final touches

# install package that provides the which command
yum -y install which
systemctl=$( which systemctl )

# capture kernel messages
echo "kern.*   /var/log/kernel" > /etc/rsyslog.d/kernel.conf

# setup skel
mkdir /tmp/build
wget -O /tmp/build/skel.zip https://github.com/gpanula/skel/archive/master.zip
cd /etc || exit 99
unzip /tmp/build/skel.zip
mv /etc/skel /etc/skel.orig
mv /etc/skel-master /etc/skel
rm -f /etc/skel/LICENSE
rm -f /etc/skel/.LICENSE
rm -f /etc/skel/README.md
chmod 640 /etc/skel/.ssh/authorized_keys2

cd /root || exit 99
mv .bashrc .bashrc.orig
cp /etc/skel/.bashrc /root/.bashrc
cp /etc/skel/.vimrc /root/.vimrc
sed -i '/set-git-info/s/^/#/' /root/.bashrc
mkdir /root/.ssh
chmod 0600 /root/.ssh
cp /etc/skel/.ssh/authorized_keys2 /root/.ssh/authorized_keys2
ln -s /root/.ssh/authorized_keys2 /root/.ssh/authorized_keys

if [ -d /home/vagrant ]; then
  rsync -ah /etc/skel/ /home/vagrant/
  chown -R vagrant:vagrant /home/vagrant
fi

wget -O /tmp/build/profile.d.zip https://github.com/gpanula/profile.d/archive/master.zip
cd /tmp/build || exit 99
unzip /tmp/build/profile.d.zip
cp /tmp/build/profile.d-master/* /etc/profile.d/
rm -f /etc/profile.d/README.md

# customize ssh
cd /etc/ssh || exit 99
mv sshd_config sshd_config.orig
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/gpanula/server_base/master/sshd_config
chmod 600 /etc/ssh/sshd_config
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.tmp && mv /etc/ssh/moduli /etc/ssh/moduli.OLD && mv /etc/ssh/moduli.tmp /etc/ssh/moduli

# allow sshd to listen on port 4242
semanage port -a -t ssh_port_t -p tcp 4242

# dynamic motd
[ -e /etc/motd ] && mv /etc/motd /etc/motd.orig
# Put "dynamic" motd in place
wget -O /usr/local/etc/system-location https://raw.githubusercontent.com/gpanula/server_base/master/system-location
wget -O /usr/local/etc/system-announcement https://raw.githubusercontent.com/gpanula/server_base/master/system-announcement
wget -O /etc/systemd/system/dynamotd.service https://raw.githubusercontent.com/gpanula/server_base/master/dynamotd.service
wget -O /etc/systemd/system/dynamotd.timer https://raw.githubusercontent.com/gpanula/server_base/master/dynamotd.timer
wget -O /usr/local/bin/dynamotd.sh https://raw.githubusercontent.com/gpanula/server_base/master/dynamotd.sh
chmod +x /usr/local/bin/dynamotd.sh
$systemctl daemon-reload
$systemctl enable dynamotd.timer
$systemctl start dynamotd.service
ln -s /var/run/motd /etc/motd

# ditch the unneed firmware
rpm -qa | grep firmware | grep -v linux | xargs yum remove -y

