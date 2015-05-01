#!/bin/bash
stop_service()
{
# ps aux | grep "lxdm.*-d" | grep -v grep | awk {'print $2'} | while read i ; do kill -9 ${i}; done
for i in lxsession x11vnc Xvfb; do pkill ${i}; done
}
initialize()
{
num=$(sed -n '/lxde-logout/=' /usr/share/lxde/openbox/menu.xml)
for i in $(expr $num - 1) $num $(expr $num - 1)
do
sed -i "${i}d" /usr/share/lxde/openbox/menu.xml
done
echo "# ban" > /usr/bin/lxde-logout
mkdir -p /var/run/sshd
mknod -m 600 /dev/console c 5 1
mknod /dev/tty0 c 4 0
if
[ -n "$USER_NAME" ]
then
result=0 && for name in $(cat /etc/passwd | cut -d ":" -f1)
do
[ "$USER_NAME" = "${name}" ] && result=$(expr $result + 1) && break
done
[ $result -ne 0 ] && USER_NAME=user
else
USER_NAME=user
fi
[ -n "$USER_PASSWORD" ] || USER_PASSWORD="pass"

useradd --create-home --shell /bin/bash --user-group --groups adm,sudo $USER_NAME

passwd $USER_NAME <<EOF >/dev/null 2>&1
$USER_PASSWORD
$USER_PASSWORD
EOF

stop_service
export DISPLAY=:1 
export HOME="/home/$USER_NAME"
echo "$USER_NAME@$USER_PASSWORD" > /home/$USER_NAME/.vncpass
}
username=$(ls /home/ | sed -n 1p)
if
[ -n "$username" ]
then
USER_NAME="$username"
else
initialize
fi
ps aux | grep -q lxdm || start-stop-daemon --background --quiet --pidfile /var/run/lxdm.pid --background --exec /usr/sbin/lxdm -- -d
su $USER_NAME <<EOF
export DISPLAY=:1 
export HOME="/home/$USER_NAME"
pidof /usr/bin/Xvfb || start-stop-daemon --start --background --pidfile /var/run/Xvfb.pid --background --exec /usr/bin/Xvfb -- :1 -screen 0 1024x640x16
pidof /usr/bin/lxsession || start-stop-daemon --start --background --pidfile /var/run/lxsession.pid --background --exec /usr/bin/lxsession -- -s LXDE -e LXDE
pidof /usr/bin/x11vnc || start-stop-daemon --start --background --pidfile /var/run/x11vnc.pid --background --exec /usr/bin/x11vnc -- -xkb -forever -display :1 -passwdfile /home/$USER_NAME/.vncpass
EOF
ps aux | grep -v grep  | grep -q "/noVNC/utils/launch.sh" || start-stop-daemon --start --quiet --pidfile /var/run/noVNC.pid --background --exec /noVNC/utils/launch.sh
exec /usr/sbin/sshd -D

