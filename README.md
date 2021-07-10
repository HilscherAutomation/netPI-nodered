## Node-RED

Made for Raspberry Pi 3B architecture based devices and compatibles

### Docker repository

https://hub.docker.com/r/hilschernetpi/netpi-nodered

### Container features

The image provided hereunder deploys a container with installed Debian, Node-RED, hardware specific Node-RED nodes and several useful common Node-RED nodes maintained by the community.

Base of the image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with installed Internet of Things flow-based programming web-tool [Node-RED](https://nodered.org/).

Additionally the nodes [node-red-contrib-opcua](https://flows.nodered.org/node/node-red-contrib-opcua), [node-red-dashboard](https://flows.nodered.org/node/node-red-dashboard), [node-red-contrib-ibm-watson-iot](https://www.npmjs.com/package/node-red-contrib-ibm-watson-iot), [node-red-contrib-azure-iot-hub](https://flows.nodered.org/node/node-red-contrib-azure-iot-hub), [node-red-contrib-modbus](https://flows.nodered.org/node/node-red-contrib-modbus), [node-red-contrib-influxdb](https://flows.nodered.org/node/node-red-contrib-influxdb), [node-red-contrib-mssql-plus](https://flows.nodered.org/node/node-red-contrib-mssql-plus) come preinstalled.

Depending on the devices /dev/... found during the container start period the nodes [node-red-contrib-npix-io](https://github.com/HilscherAutomation/netPI-nodered-npix-io/tree/master/node-red-contrib-npix-io) (`/dev/gpiomem`), [node-red-contrib-npix-ai](https://github.com/HilscherAutomation/netPI-nodered-npix-ai/tree/master/node-red-contrib-npix-ai) (`/dev/i2c-1`), [node-red-contrib-user-leds](https://github.com/HilscherAutomation/netPI-nodered-user-leds/tree/master/node-red-contrib-user-leds) (`/dev/gpiomem`), [node-red-contrib-npix-leds](https://github.com/HilscherAutomation/netPI-nodered-npix-leds/tree/master/node-red-contrib-npix-leds) (`/dev/gpiomem`), [node-red-contrib-generic-ble](https://www.npmjs.com/package/node-red-contrib-generic-ble) (`/dev/ttyAMA0,/dev/vcio`), [node-red-node-serialport](https://flows.nodered.org/node/node-red-node-serialport) (`/dev/ttyS0`), [node-red-contrib-canbus](https://flows.nodered.org/node/node-red-contrib-canbus) (`/dev/i2c-1`), [node-red-contrib-fieldbus](https://github.com/HilscherAutomation/netPI-nodered-fieldbus) (`/dev/spidev0.0`), [node-red-contrib-fram](https://github.com/HilscherAutomation/netPI-nodered-fram/tree/master/node-red-contrib-fram) (`/dev/i2c-1`) are dynamically installed during runtime.

### Container hosts

The container has been successfully tested on the following hosts

* netPI, model RTE 3, product name NIOT-E-NPI3-51-EN-RE
* netPI, model CORE 3, product name NIOT-E-NPI3-EN
* netFIELD Connect, product name NIOT-E-TPI51-EN-RE/NFLD
* Raspberry Pi, model 3B

netPI devices specifically feature a restricted Docker protecting the system software's integrity by maximum. The restrictions are

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container setup

#### Volume mapping (optional)

To store the Node-RED flow and settings files permanently on the Docker host they can be outsourced in a "separate" volume outside the container. This keeps the files on the system even if the container is removed. If later the volume is remapped to a new container the files are available again to it and reused.

#### Port mapping, network mode

The container needs to run in `host` network mode. 

This mode makes port mapping unnecessary. The following TCP/UDP container ports are exposed to the host automatically

Used port | Protocol | By application | Remark
:---------|:------ |:------ |:-----
*1880* | TCP | Node-RED
*9000* | TCP | Fieldbus configurator | if node-red-contrib-fieldbus active

#### Host devices

To grant access to the onboard BCM bluetooth chip the `/dev/ttyAMA0` host device needs to be added to the container. To prevent the container from failing to load the bluetooth chip with firmware (after soft restart), the chip is physically reset during each container start. To grant access to the reset logic the `/dev/vcio` host device needs to be added to the container.

To grant acccess to the GPIO signals in general the `/dev/gpiomem` host device needs to be added to the container.

For NIOT-E-NPIX-RS232, NIOT-E-NPIX-RS485 serial port plug-in modules support:

To grant access to the serial port the device `/dev/ttyS0` needs to be added to the container. It needs an NPIX module attached during system boot process to be available. (NIOT-E-NPIX-RS485 note: set GPIO 17 to '1' to activate TX/RX auto direction feature on revision #2 of this hadrware).

For netPI RTE 3 and netFIELD Connect targets:

To grant access to the onboard netX industrial network controller the `/dev/spidev0.0` host device needs to be added to the container.

To grant access to the onboard FRAM memory the `/dev/i2c-1` host device needs to be added to the container.

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the host directly. 

#### Environment variables

For netPI RTE 3 and netFIELD Connect targets only:

The type of field network protocol supported by the fieldbus nodes can be specified with the following variable

* **FIELD** with value `pns` to load PROFINET IO device or value `eis` to load EtherNet/IP adapter network protocol. If the value is set to `none` the fieldbus nodes are not available at all.

### Container deployments

Pulling the image may take 10 minutes.

#### netPI example

STEP 1. Open netPI's web UI in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Click *Volumes > + Add Volume*. Enter `nodered` as *Name* and click `Create the volume`. 

STEP 4. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-nodered** |
*Adv.con.set. > Network > Network* | **host** |
*Adv.con.set. > Restart policy* | **always**
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/ttyAMA0** -> *Container path* **/dev/ttyAMA0** | optional for Bluetooth
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/vcio** -> *Container path* **/dev/vcio** | optiona for Bluetooth
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/gpiomem** -> *Container path* **/dev/gpiomem** | optional for NPIX DIO, AIU
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** | optional for Fieldbus
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/i2c-1** -> *Container path* **/dev/i2c-1** | optional for FRAM, NPIX CAN
*Adv.con.set. > Runt. & Res. > +add device* | *Host path* **/dev/ttyS0** -> *Container path* **/dev/ttyS0** | optional for NPIX serial
*Adv.con.set. > Runt. & Res. > Privileged mode* | **On** |
*Adv.con.set. > Env > +add env.var.* | *name* **FIELD** -> *value* **pns** or **eis** | optional for netPI RTE 3, netFIELD Connect
*Adv.con.set. > Volumes > +map additional volume* | *volume* **/nodered** -> *container* **/root/.node-red** | optional for flow persistence

STEP 5. Press the button *Actions > Start/Deploy container*

#### Docker command line example

`docker volume create nodered` `&&`
`docker run -d --privileged --network=host --restart=always -e FIELD=pns --device=/dev/ttyAMA0:/dev/ttyAMA0 --device=/dev/vcio:/dev/vcio --device=/dev/gpiomem:/dev/gpiomem --device=/dev/spidev0.0:/dev/spidev0.0 --device=/dev/i2c-1:/dev/i2c-1 -v nodered:/root/.node-red -p 1880:1880/tcp -p 9000:9000/tcp hilschernetpi/netpi-nodered`

#### Docker compose example

A `docker-compose.yml` file could look like this

    version: "2"

    services:
     nodered:
       image: hilschernetpi/netpi-nodered
       restart: always
       privileged: true
       network_mode: host
       ports:
         - 1880:1880
         - 9000:9000
       devices:
         - "/dev/ttyAMA0:/dev/ttyAMA0"
         - "/dev/vcio:/dev/vcio"
         - "/dev/gpiomem:/dev/gpiomem"
         - "/dev/spidev0.0:/dev/spidev0.0"
         - "/dev/i2c-1:/dev/i2c-1"
       volumes:
         - nodered:/root/.node-red
       environment:
         - FIELD=pns

    volumes:
      nodered:
### Container access

The container starts Node-RED and all involved services automatically when deployed.

The container configures Node-RED to support https secured web communications. So open it in your browser with `https://<device-ip-address>:1880` e.g. `https://192.168.0.1:1880`.

The container configures Node-RED to ask for a login in case it runs on a device with admin web UI like netPI or netFIELD Connect. Use the same users/password as setup in the UI to login.

### License

Copyright (c) Hilscher Gesellschaft fuer Systemautomation mbH. All rights reserved.
Licensed under the LICENSE.txt file information stored in the project's source code repository.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
