#!/bin/bash +e

#check if container is running in host mode
if [[ -z `grep "docker0" /proc/net/dev` ]]; then
  echo "Container not running in host mode. Sure you configured host network mode? Container stopped."
  exit 143
fi

#check if container is running in privileged mode
ip link add dummy0 type dummy >/dev/null 2>&1
if [[ -z `grep "dummy0" /proc/net/dev` ]]; then
  echo "Container not running in privileged mode. Sure you configured privileged mode? Container stopped."
  exit 143
else
  # clean the dummy0 link
  ip link delete dummy0 >/dev/null 2>&1
fi

# start dbus as background task
/etc/init.d/dbus start

pidbt=0

# catch signals as PID 1 in a container
# SIGNAL-handler
term_handler() {

  echo "stopping bluetooth daemon ..."
  if [ $pidbt -ne 0 ]; then
        kill -SIGTERM "$pidbt"
        wait "$pidbt"
        echo "bring hci0 down ..."
        hciconfig hci0 down
  fi

  echo "terminating dbus ..."
  /etc/init.d/dbus stop


  exit 143; # 128 + 15 -- SIGTERM
}

# on callback, stop all started processes in term_handler
trap 'kill ${!}; term_handler' SIGINT SIGKILL SIGTERM SIGQUIT SIGTSTP SIGSTOP SIGHUP

#check if we have a user V1 management running
httpUrl='https://127.0.0.1/getLandingPageStructure'
rep=$(curl -k -s $httpUrl)
if [[ $rep == *'model-name'* ]]; then
  sed -i -e 's+//adminAuth: {+adminAuth: require("./user-authentication_v1.js"),\n    //adminAuth: {+' /usr/lib/node_modules/node-red/settings.js
else
  sed -i -e 's+adminAuth: require("./user-authentication_v1.js"),\n    //adminAuth: {+//adminAuth: {+' /usr/lib/node_modules/node-red/settings.js
fi


#check if we have a user V2 management running
httpUrl='https://127.0.0.1/cockpit/login'
rep=$(curl -k -s $httpUrl)
if [[ $rep == *'Authentication failed'* ]]; then
  sed -i -e 's+//adminAuth: {+adminAuth: require("./user-authentication_v2.js"),\n    //adminAuth: {+' /usr/lib/node_modules/node-red/settings.js
else
  sed -i -e 's+adminAuth: require("./user-authentication_v2.js"),\n    //adminAuth: {+//adminAuth: {+' /usr/lib/node_modules/node-red/settings.js
fi

#make hardware dependent nodes dynamically available or unavailable

#check 4DI4DO, NPIX-LEDs, USER-LEDs nodes support
if [[ -e "/dev/gpiomem" ]]; then
  echo "Precondition for node-red-contrib-npix-io node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-npix-io /usr/lib/node_modules/node-red-contrib-npix-io
  echo "Precondition for node-red-contrib-user-leds node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-user-leds /usr/lib/node_modules/node-red-contrib-user-leds
  echo "Precondition for node-red-contrib-npix-leds node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-npix-leds /usr/lib/node_modules/node-red-contrib-npix-leds
else
  rm -f /usr/lib/node_modules/node-red-contrib-npix-io
  rm -f /usr/lib/node_modules/node-red-contrib-user-leds
  rm -f /usr/lib/node_modules/node-red-contrib-npix-leds
fi

#check FRAM, 4AI16U, CAN nodes support
if [[ -e "/dev/i2c-1" ]]; then
  echo "Precondition for node-red-contrib-fram node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-fram /usr/lib/node_modules/node-red-contrib-fram 
  echo "Precondition for node-red-contrib-npix-ai node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-npix-ai /usr/lib/node_modules/node-red-contrib-npix-ai
  echo "Precondition for node-red-contrib-canbus node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-canbus /usr/lib/node_modules/node-red-contrib-canbus
else
  rm -f /usr/lib/node_modules/node-red-contrib-fram
  rm -f /usr/lib/node_modules/node-red-contrib-npix-ai
  rm -f /usr/lib/node_modules/node-red-contrib-canbus
fi


#check serial port node support
if [[ -e "/dev/ttyS0" ]]; then
  echo "Precondition for node-red-node-serialport node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-node-serialport /usr/lib/node_modules/node-red-node-serialport 
else
  rm -f /usr/lib/node_modules/node-red-node-serialport
fi


#check bluetooth node support
if [[ -e "/dev/ttyAMA0" ]] && [[ -e "/dev/vcio" ]]; then
  echo "Precondition for node-red-contrib-generic-ble node(s) met. Installing node(s)." 
  ln -s -f /usr/lib/node_modules_tmp/node-red-contrib-generic-ble /usr/lib/node_modules/node-red-contrib-generic-ble

  #reset BCM chip (making sure get access even after container restart)
  /opt/vc/bin/vcmailbox 0x38041 8 8 128 0 >/dev/null
  sleep 1
  /opt/vc/bin/vcmailbox 0x38041 8 8 128 1 >/dev/null
  sleep 1

  #load firmware to BCM chip and attach to hci0
  hciattach /dev/ttyAMA0 bcm43xx 115200 noflow

  #create hci0 device
  hciconfig hci0 up

  #start bluetooth daemon
  /usr/libexec/bluetooth/bluetoothd -d &
  pidbt="$!"

else
  rm -f /usr/lib/node_modules/node-red-contrib-generic-ble
fi

#check if fieldbus node support is not desired
if [ ! "$FIELD" = "none" ]
then
  #check fieldbus node support
  if [[ -e "/dev/spidev0.0" ]]; then
    echo "Precondition for node-red-fieldbus node(s) met. Installing node(s)." 
    ln -s -f /usr/lib/node_modules_tmp/fieldbus /usr/lib/node_modules/fieldbus

    if [ "$FIELD" = "pns" ]
    then
      firmware="R160D000.nxf"
    elif [ "$FIELD" = "eis" ]
    then
      firmware="R160H000.nxf"
    else
      firmware="R160D000.nxf"
    fi

    #copy firmware to location where driver will load it from
    if [ ! -f /opt/cifx/deviceconfig/FW/channel0/*.nxf ]; then
      cp /root/.node-red/FWnetPI/$firmware /opt/cifx/deviceconfig/FW/channel0/$firmware
    fi

    # start Fieldbus Web configurator as background task
    cd /usr/lib/node_modules_tmp/WebConfigurator/ServerContent/
    node app.js &
  else
    rm -f /usr/lib/node_modules/fieldbus
  fi
fi

# start Node-RED as background task
/usr/bin/node-red &

# wait forever not to exit the container
while true
do
  tail -f /dev/null & wait ${!}
done

exit 0
