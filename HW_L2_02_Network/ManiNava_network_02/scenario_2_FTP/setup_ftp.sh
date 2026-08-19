#!/bin/bash

# ftp server setup (vsftpd)
# tested on debian/ubuntu. on arch: sudo pacman -S vsftpd

# run everything as root
if [ "$EUID" -ne 0 ]; then
  echo "please run with sudo"
  exit 1
fi

FTP_USER="ftpuser"
FTP_PASS="ftpuser123"

echo "== 1. installing vsftpd =="
apt update && apt install -y vsftpd

echo "== 2. writing configuration =="
cp /etc/vsftpd.conf /etc/vsftpd.conf.bak 2>/dev/null
cat > /etc/vsftpd.conf <<'EOF'
# basic vsftpd config - see vsftpd.conf in this folder for annotated version
listen=YES
anonymous_enable=YES
anon_root=/srv/ftp
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
local_umask=022
anon_upload_enable=NO
xferlog_enable=YES
connect_from_port_20=YES
EOF

echo "== 3. creating dedicated ftp user =="
id "$FTP_USER" &>/dev/null || useradd -m -d /home/"$FTP_USER" -s /bin/bash "$FTP_USER"
echo "$FTP_USER:$FTP_PASS" | chpasswd
mkdir -p /home/"$FTP_USER"/files
chown "$FTP_USER":"$FTP_USER" /home/"$FTP_USER"/files
# anonymous download folder
mkdir -p /srv/ftp/pub
echo "welcome to the test ftp server" > /srv/ftp/pub/readme.txt

echo "== 4. start / stop / status =="
# start:   systemctl start vsftpd   (or: vsftpd /etc/vsftpd.conf)
# stop:    systemctl stop vsftpd
# restart: systemctl restart vsftpd
# status:  systemctl status vsftpd
systemctl restart vsftpd || service vsftpd restart

echo "== done =="
ss -tuln | grep :21 && echo "vsftpd is listening on port 21"
