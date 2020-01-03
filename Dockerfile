#STEP 1 of multistage build ---Compile Bluetooth stack-----

#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:stretch-20191223 as builder

#enable cross compiling (comment out next line if built on Raspberry Pi) 
RUN [ "cross-build-start" ]

#environment variables
ENV BLUEZ_VERSION 5.50 

RUN apt-get update && apt-get install -y \
    build-essential wget \
    libical-dev libdbus-1-dev libglib2.0-dev libreadline-dev libudev-dev systemd

RUN wget -P /tmp/ https://www.kernel.org/pub/linux/bluetooth/bluez-${BLUEZ_VERSION}.tar.gz \
 && tar xf /tmp/bluez-${BLUEZ_VERSION}.tar.gz -C /tmp \
#compile bluez
 && cd /tmp/bluez-${BLUEZ_VERSION} \
 && ./configure --prefix=/usr \
    --mandir=/usr/share/man \
    --sysconfdir=/etc \
    --localstatedir=/var \
    --enable-library \
    --enable-experimental \
    --enable-maintainer-mode \
    --enable-deprecated \
 && make \
#install bluez tools
 && make install
#disable cross compiling (comment out next line if built on Raspberry Pi) 
RUN [ "cross-build-end" ]


#STEP 2 of multistage build ----Create the final image-----

#use armv7hf compatible base image
FROM balenalib/armv7hf-debian:stretch-20191223

#dynamic build arguments coming from the /hooks/build file
ARG BUILD_DATE
ARG VCS_REF

#metadata labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/HilscherAutomation/netPI-nodered" \
      org.label-schema.vcs-ref=$VCS_REF

#enable cross compiling (comment out next line if built on Raspberry Pi)
RUN [ "cross-build-start" ]

#version
ENV HILSCHERNETPI_NODERED_VERSION 1.3.2

#labeling
LABEL maintainer="netpi@hilscher.com" \
      version=$HILSCHERNETPI_NODERED_VERSION \
      description="Node-RED including common and netPI specific Node-RED nodes" \
      tag=$IMAGE_TAG


# -------------------- Install netPI specific nodes --------------------------------------

ARG FIELDBUS_NODE=netPI-nodered-fieldbus
ARG FIELDBUS_NODE_VERSION=1.0.5
ARG FIELDBUS_NODE_DIR=/tmp/${FIELDBUS_NODE}-${FIELDBUS_NODE_VERSION}

ARG FRAM_NODE=netPI-nodered-fram
ARG FRAM_NODE_VERSION=1.1.0
ARG FRAM_NODE_DIR=/tmp/${FRAM_NODE}-${FRAM_NODE_VERSION}

ARG USER_LEDS_NODE=netPI-nodered-user-leds
ARG USER_LEDS_NODE_VERSION=1.0.0
ARG USER_LEDS_NODE_DIR=/tmp/${USER_LEDS_NODE}-${USER_LEDS_NODE_VERSION}

ARG NPIX_LEDS_NODE=netPI-nodered-npix-leds
ARG NPIX_LEDS_NODE_VERSION=0.9.3
ARG NPIX_LEDS_NODE_DIR=/tmp/${NPIX_LEDS_NODE}-${NPIX_LEDS_NODE_VERSION}

ARG NPIX_AI_NODE=netPI-nodered-npix-ai
ARG NPIX_AI_NODE_VERSION=1.0.3
ARG NPIX_AI_NODE_DIR=/tmp/${NPIX_AI_NODE}-${NPIX_AI_NODE_VERSION}

ARG NPIX_IO_NODE=netPI-nodered-npix-io
ARG NPIX_IO_NODE_VERSION=1.0.2
ARG NPIX_IO_NODE_DIR=/tmp/${NPIX_IO_NODE}-${NPIX_IO_NODE_VERSION}


RUN curl https://codeload.github.com/HilscherAutomation/${FIELDBUS_NODE}/tar.gz/${FIELDBUS_NODE_VERSION} -o /tmp/${FIELDBUS_NODE} \
 && curl https://codeload.github.com/HilscherAutomation/${FRAM_NODE}/tar.gz/${FRAM_NODE_VERSION} -o /tmp/${FRAM_NODE} \
 && curl https://codeload.github.com/HilscherAutomation/${USER_LEDS_NODE}/tar.gz/${USER_LEDS_NODE_VERSION} -o /tmp/${USER_LEDS_NODE} \
 && curl https://codeload.github.com/HilscherAutomation/${NPIX_LEDS_NODE}/tar.gz/${NPIX_LEDS_NODE_VERSION} -o /tmp/${NPIX_LEDS_NODE} \
 && curl https://codeload.github.com/HilscherAutomation/${NPIX_AI_NODE}/tar.gz/${NPIX_AI_NODE_VERSION} -o /tmp/${NPIX_AI_NODE} \
 && curl https://codeload.github.com/HilscherAutomation/${NPIX_IO_NODE}/tar.gz/${NPIX_IO_NODE_VERSION} -o /tmp/${NPIX_IO_NODE} \
 && tar -xvf /tmp/${FIELDBUS_NODE} -C /tmp/ \
 && tar -xvf /tmp/${FRAM_NODE} -C /tmp/ \
 && tar -xvf /tmp/${USER_LEDS_NODE} -C /tmp/ \
 && tar -xvf /tmp/${NPIX_AI_NODE} -C /tmp/ \
 && tar -xvf /tmp/${NPIX_IO_NODE} -C /tmp/ \
 && tar -xvf /tmp/${NPIX_LEDS_NODE} -C /tmp/ \
# -------------------- Install nodejs and Node-RED --------------------------------------
#install node.js V8.x.x and Node-RED 0.20.x
 && apt-get update && apt-get install build-essential python-dev python-pip python-setuptools \
 && curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -  \
 && apt-get install -y nodejs  \
 && npm install -g --unsafe-perm node-red@0.20.8 \
 && npm config set package-lock false \
#configure user login & https security
 && sed -i -e 's+//var fs = require("fs");+var fs = require("fs");+' /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    key: fs.readFileSync('privatekey.pem'),+https: {\n    key: fs.readFileSync('/root/.node-red/certs/node-key.pem'),+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//    cert: fs.readFileSync('certificate.pem')+cert: fs.readFileSync('/root/.node-red/certs/node-cert.pem')\n    },+" /usr/lib/node_modules/node-red/settings.js \
 && sed -i -e "s+//requireHttps: true,+requireHttps: true,+" /usr/lib/node_modules/node-red/settings.js \
 && mkdir -p /root/.node-red/node_modules \
 && cd /root/.node-red \
 && npm install when request \
 && mkdir -p /root/.node-red/certs \
 && cd /root/.node-red/certs \
 && openssl genrsa -out ./node-key.pem 2048 \
 && openssl req -new -sha256 -key ./node-key.pem -out ./node-csr.pem -subj "/C=DE/ST=Hessen/L=Hattersheim/O=Hilscher/OU=Hilscher/CN=myown/emailAddress=myown@hilscher.com" \
 && openssl x509 -req -in ./node-csr.pem -signkey ./node-key.pem -out ./node-cert.pem \
# -------------------- Install GPIO python lib --------------------------------------
 && pip install wheel \
 && pip install RPi.GPIO \
# -------------------- Install Fieldbus node and all dependencies --------------------
# install all additional tools
 && apt-get install libboost-filesystem1.62-dev libboost-date-time1.62-dev libjansson-dev p7zip-full \
#install netx driver
 && dpkg -i ${FIELDBUS_NODE_DIR}/driver/netx-docker-pi-drv-1.1.3.deb \
#compile program checking we are running on netPI RTE 3
 && mv ${FIELDBUS_NODE_DIR}/driver/checkdevicetype.c /opt/cifx \
 && gcc /opt/cifx/checkdevicetype.c -o /opt/cifx/checkdevicetype -I /usr/include/cifx -lcifx \
 && chmod +x /opt/cifx/checkdevicetype \
#install web fieldbus configurator
 && 7z -t7z -r -v: x "${FIELDBUS_NODE_DIR}/web-configurator-fieldbus/WebConfigurator_V1.0200.1000.7z" -o/usr/lib/node_modules_tmp \
 && mv "/usr/lib/node_modules_tmp/WebConfigurator V1.0200.1000" "/usr/lib/node_modules_tmp/WebConfigurator" \
 && cd /usr/lib/node_modules_tmp/WebConfigurator/ServerContent/ \
 && npm install \
#make some changes in the fielbus configurator setup file
 && sed -i -e 's;"uiHost": "127.0.0.1";\"uiHost": "";' ServerSettings.json \
 && sed -i -e 's;"configuration-file-path": "/opt/node-red/.userdir";\"configuration-file-path": "/root/.node-red/";' ServerSettings.json \
 && sed -i -e 's;"platform": "ntijcxgb";\"platform": "npi3";' ServerSettings.json \
#install fieldbus nodes
 && mkdir -p /root/.node-red \
 && mv ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/fieldbusSettings.json /root/.node-red \
 && mkdir -p /usr/lib/node_modules_tmp/fieldbus/lib \
 && mv ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/10-fieldbus.html \
    ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/10-fieldbus.js \
    ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/package.json -t \
    /usr/lib/node_modules_tmp/fieldbus \
 && mv ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/lib/fieldbusConnectionPool.js \
    ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/lib/fieldbusHandler.js \
    ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/lib/HilscherLog.js \
    ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/lib/HilscherToolBox.js \
    /usr/lib/node_modules_tmp/fieldbus/lib \
 && cd /usr/lib/node_modules_tmp/fieldbus \
 && npm install \
 && sed -i -e 's;window.location.protocol;"http:";' 10-fieldbus.html \
 && cd /root/.node-red \
 && npm rebuild \
#install fieldbus nodes wrapper library and generate needed libboost V1.61.0 links
 && mv ${FIELDBUS_NODE_DIR}/node-red-contrib-fieldbus/lib/fieldbus.node /usr/lib/node_modules_tmp/fieldbus/lib \
 && ln -s /usr/lib/arm-linux-gnueabihf/libboost_filesystem.so.1.62.0 /usr/lib/arm-linux-gnueabihf/libboost_filesystem.so.1.61.0 \
 && ln -s /usr/lib/arm-linux-gnueabihf/libboost_system.so.1.62.0 /usr/lib/arm-linux-gnueabihf/libboost_system.so.1.61.0 \
#install netx firmwares from zip
 && mkdir /opt/cifx/deviceconfig/FW/channel0 \
 && 7z -tzip -r -v: x "${FIELDBUS_NODE_DIR}/firmwares/FWPool.zip" -o/root/.node-red \
# -------------------- Install FRAM node and all dependencies --------------------
 && mkdir /usr/lib/node_modules_tmp/node-red-contrib-fram \
 && mv ${FRAM_NODE_DIR}/node-red-contrib-fram/fram.js \
    ${FRAM_NODE_DIR}/node-red-contrib-fram/fram.html \
    ${FRAM_NODE_DIR}/node-red-contrib-fram/package.json \
    -t /usr/lib/node_modules_tmp/node-red-contrib-fram \
 && cd /usr/lib/node_modules_tmp/node-red-contrib-fram \
 && npm install \
# -------------------- Install netPI user LED nodes and all dependencies --------------------
 && mkdir /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
 && mv ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/netiot-io-led.js \
    ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/netiot-io-led.html \
    ${USER_LEDS_NODE_DIR}/node-red-contrib-user-leds/package.json \
    -t /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
 && cd /usr/lib/node_modules_tmp/node-red-contrib-user-leds \
 && npm install \
 && mkdir /var/platform \
 && cd /var/platform \
 && ln -s /sys/class/leds/user0:orange:user/brightness led_led2 \
 && ln -s /sys/class/leds/user1:orange:user/brightness led_led1 \
# -------------------- Install NPIX LED nodes and all dependencies --------------------
 && mkdir /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
 && mv ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/npixleds.js \
    ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/npixleds.html \
    ${NPIX_LEDS_NODE_DIR}/node-red-contrib-npix-leds/package.json \
    -t /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
 && cd /usr/lib/node_modules_tmp/node-red-contrib-npix-leds \
 && npm install \ 
# -------------------- Install NPIX 4AI16U nodes and all dependencies --------------------
 && mkdir /usr/lib/node_modules_tmp/node-red-contrib-npix-ai \
 && mv ${NPIX_AI_NODE_DIR}/node-red-contrib-npix-ai/npixai.js \ 
    ${NPIX_AI_NODE_DIR}/node-red-contrib-npix-ai/npixai.html \
    ${NPIX_AI_NODE_DIR}/node-red-contrib-npix-ai/package.json \
    -t /usr/lib/node_modules_tmp/node-red-contrib-npix-ai \
 && cd /usr/lib/node_modules_tmp/node-red-contrib-npix-ai \
 && npm install \
# -------------------- Install NPIX 4DI4DO nodes and all dependencies --------------------
 && mkdir /usr/lib/node_modules_tmp/node-red-contrib-npix-io \
 && mv ${NPIX_IO_NODE_DIR}/node-red-contrib-npix-io/npixio.js \
    ${NPIX_IO_NODE_DIR}/node-red-contrib-npix-io/npixio.html \
    ${NPIX_IO_NODE_DIR}/node-red-contrib-npix-io/package.json \
    -t /usr/lib/node_modules_tmp/node-red-contrib-npix-io \
 && cd /usr/lib/node_modules_tmp/node-red-contrib-npix-io \
 && npm install \
 && cd /usr/lib/ \
# -------------------- Install Modbus nodes and all dependencies --------------------
 && npm install node-red-contrib-modbus@4.1.3 \
# -------------------- Install Dashboard nodes and all dependencies -----------------
 && npm install node-red-dashboard@2.16.3 \
# -------------------- Install OPC UA nodes and all dependencies --------------------
 && npm install node-red-contrib-opcua@0.2.49 \
# -------------------- Install IBM Watson IoT nodes and all dependencies --------------------
 && npm install node-red-contrib-ibm-watson-iot@0.2.8 \
# -------------------- Install IBM Watson IoT nodes and all dependencies --------------------
 && npm install node-red-contrib-ibm-watson-iot \
# -------------------- Install Microsoft Azure IoT Hub nodes and all dependencies --------------------
 && npm install node-red-contrib-azure-iot-hub@0.4.0 \
# -------------------- Install influxdb node and all dependencies --------------------
 && npm install node-red-contrib-influxdb@0.3.1 \
# -------------------- Install MSSQL database node and all dependencies --------------------
 && npm install node-red-contrib-mssql-plus@0.3.0 \
# -------------------- Install SMB file access node and all dependencies --------------------
 && npm install node-red-contrib-smb@1.1.1 \
# -------------------- Install S7 communication nodes and all dependencies --------------------
 && cd /usr/lib/ \
 && npm install node-red-contrib-s7comm@1.1.6 \
 && cd /usr/lib/node_modules/node-red-contrib-s7comm/node_modules \
 && npm install net-keepalive@1.2.1 \
# -------------------- Install serial port node and all dependencies --------------------
 && cd /usr/lib/ \
 && npm install node-red-node-serialport@0.8.6 \ 
 && mv /usr/lib/node_modules/node-red-node-serialport /usr/lib/node_modules_tmp \
# -------------------- Install socketCAN nodes and all dependencies --------------------
 && cd /usr/lib/ \
 && npm install node-red-contrib-canbus@1.0.1 \
 && mv /usr/lib/node_modules/node-red-contrib-canbus /usr/lib/node_modules_tmp \
# -------------------- Install Bluetooth stack and all dependencies --------------------
 && cd /usr/lib/ \
 && apt-get install libudev-dev \
 && npm install node-red-contrib-generic-ble@3.1.0 \
 && mv /usr/lib/node_modules/node-red-contrib-generic-ble /usr/lib/node_modules_tmp \
 && apt-get install -y dbus git libglib2.0-dev \
#get BCM chip firmware 
 && mkdir /etc/firmware \
 && curl -o /etc/firmware/BCM43430A1.hcd -L https://github.com/OpenELEC/misc-firmware/raw/master/firmware/brcm/BCM43430A1.hcd \
#create folders for bluetooth tools
 && mkdir -p '/usr/bin' '/usr/libexec/bluetooth' '/usr/lib/cups/backend' '/etc/dbus-1/system.d' \
    '/usr/share/dbus-1/services' '/usr/share/dbus-1/system-services' '/usr/include/bluetooth' \
    '/usr/share/man/man1' '/usr/share/man/man8' '/usr/lib/pkgconfig' '/usr/lib/bluetooth/plugins' \
    '/lib/udev/rules.d' '/lib/systemd/system' '/usr/lib/systemd/user' '/lib/udev' \
#install userland raspberry tools
 && git clone -b "1.20180417" --single-branch --depth 1 https://github.com/raspberrypi/firmware /tmp/firmware \
 && mv /tmp/firmware/hardfp/opt/vc /opt \
 && echo "/opt/vc/lib" >/etc/ld.so.conf.d/00-vmcs.conf \
 && /sbin/ldconfig \
 && rm -rf /opt/vc/src \
#clean up
 && apt-get remove git p7zip-full \
 && apt-get autoremove \
 && rm -rf /tmp/* \
 && rm -rf /var/lib/apt/lists/*

# -------------------- Do all necessary copies --------------------

COPY "./auth/*" /root/.node-red/

#copy bluez tools from builder container
COPY --from=builder /usr/bin/bluetoothctl /usr/bin/btmon /usr/bin/rctest /usr/bin/l2test /usr/bin/l2ping \
                    /usr/bin/bccmd /usr/bin/bluemoon /usr/bin/hex2hcd /usr/bin/mpris-proxy /usr/bin/btattach \
                    /usr/bin/hciattach /usr/bin/hciconfig /usr/bin/hcitool /usr/bin/hcidump /usr/bin/rfcomm \
                    /usr/bin/sdptool /usr/bin/ciptool /usr/bin/
COPY --from=builder /usr/libexec/bluetooth/bluetoothd /usr/libexec/bluetooth/obexd /usr/libexec/bluetooth/
COPY --from=builder /usr/lib/cups/backend/bluetooth /usr/lib/cups/backend/
COPY --from=builder /etc/dbus-1/system.d/bluetooth.conf /etc/dbus-1/system.d/
COPY --from=builder /usr/share/dbus-1/services/org.bluez.obex.service /usr/share/dbus-1/services/
COPY --from=builder /usr/share/dbus-1/system-services/org.bluez.service /usr/share/dbus-1/system-services/
COPY --from=builder /usr/include/bluetooth/* /usr/include/bluetooth/
COPY --from=builder /usr/share/man/man1* /usr/share/man/man1/
COPY --from=builder /usr/share/man/man8/bluetoothd.8 /usr/share/man/man8/
COPY --from=builder /usr/lib/pkgconfig/bluez.pc /usr/lib/pkgconfig/
COPY --from=builder /usr/lib/bluetooth/plugins/external-dummy.so /usr/lib/bluetooth/plugins/
COPY --from=builder /usr/lib/bluetooth/plugins/external-dummy.la /usr/lib/bluetooth/plugins/
COPY --from=builder /lib/udev/rules.d/97-hid2hci.rules /lib/udev/rules.d/
COPY --from=builder /lib/systemd/system/bluetooth.service /lib/systemd/system/
COPY --from=builder /usr/lib/systemd/user/obex.service /usr/lib/systemd/user/
COPY --from=builder /lib/udev/hid2hci /lib/udev/

#copy files
COPY "./init.d/*" /etc/init.d/

#set the entrypoint
ENTRYPOINT ["/etc/init.d/entrypoint.sh"]

#set STOPSGINAL
STOPSIGNAL SIGTERM

#disable cross compiling (comment out next line if built on Raspberry Pi)
RUN [ "cross-build-end" ]
