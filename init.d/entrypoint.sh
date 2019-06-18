#!/bin/bash +e
# catch signals as PID 1 in a container

# SIGNAL-handler
term_handler() {

  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

# start Node-RED as background task
if [[ $IMAGE_TAG == "CORE3" ]]; then
  /usr/bin/node-red &
fi

if [[ $IMAGE_TAG == "RTE3" ]]; then
  /opt/cifx/checkdevicetype | xargs /etc/init.d/nodered.sh start
fi

# start Fieldbus Web configurator as background task
/etc/init.d/webconfig.sh start

# start dbus as background task
/etc/init.d/dbus start

#reset BCM chip (making sure get access even after container restart)
/opt/vc/bin/vcmailbox 0x38041 8 8 128 0
sleep 1
/opt/vc/bin/vcmailbox 0x38041 8 8 128 1
sleep 1

#load firmware to BCM chip and attach to hci0
hciattach /dev/ttyAMA0 bcm43xx 921600 noflow

#create hci0 device
hciconfig hci0 up

#start bluetooth daemon
/usr/libexec/bluetooth/bluetoothd -d &

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
