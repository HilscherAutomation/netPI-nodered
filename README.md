## Node-RED

[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-nodered.svg)](https://microbadger.com/images/hilschernetpi//netpi-nodered "Node-RED")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-nodered.svg)](https://registry.hub.docker.com/r/hilschernetpi/netpi-nodered/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-nodered&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-nodered "Image last updated")&nbsp;

Made for [netPI](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Secured netPI Docker

netPI features a restricted Docker protecting the system software's integrity by maximum. The restrictions are 

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container features

The image provided hereunder deploys a container with installed Debian, Node-RED, netPI specific Node-RED nodes and several useful common Node-RED nodes maintained by the community.

Base of the image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with installed Internet of Things flow-based programming web-tool [Node-RED](https://nodered.org/).

Additionally the nodes [node-red-contrib-opcua](https://flows.nodered.org/node/node-red-contrib-opcua), [node-red-dashboard](https://flows.nodered.org/node/node-red-dashboard), [node-red-contrib-ibm-watson-iot](https://www.npmjs.com/package/node-red-contrib-ibm-watson-iot), [node-red-contrib-azure-iot-hub](https://flows.nodered.org/node/node-red-contrib-azure-iot-hub), [node-red-contrib-modbus](https://flows.nodered.org/node/node-red-contrib-modbus), [node-red-contrib-influxdb](https://flows.nodered.org/node/node-red-contrib-influxdb), [node-red-contrib-mssql-plus](https://flows.nodered.org/node/node-red-contrib-mssql-plus) come preinstalled.

Depending on the devices /dev/... found during the container start period the nodes [node-red-contrib-npix-io](https://github.com/HilscherAutomation/netPI-nodered-npix-io/tree/master/node-red-contrib-npix-io) (`/dev/gpiomem`), [node-red-contrib-npix-ai](https://github.com/HilscherAutomation/netPI-nodered-npix-ai/tree/master/node-red-contrib-npix-ai) (`/dev/i2c-1`), [node-red-contrib-user-leds](https://github.com/HilscherAutomation/netPI-nodered-user-leds/tree/master/node-red-contrib-user-leds) (`/dev/gpiomem`), [node-red-contrib-npix-leds](https://github.com/HilscherAutomation/netPI-nodered-npix-leds/tree/master/node-red-contrib-npix-leds) (`/dev/gpiomem`), [node-red-contrib-generic-ble](https://www.npmjs.com/package/node-red-contrib-generic-ble) (`/dev/ttyAMA0,/dev/vcio`), [node-red-node-serialport](https://flows.nodered.org/node/node-red-node-serialport) (`/dev/ttyS0`), [node-red-contrib-canbus](https://flows.nodered.org/node/node-red-contrib-canbus) (`/dev/i2c-1`), [node-red-contrib-fieldbus](https://github.com/HilscherAutomation/netPI-nodered-fieldbus) (`/dev/spidev0.0`), [node-red-contrib-fram](https://github.com/HilscherAutomation/netPI-nodered-fram/tree/master/node-red-contrib-fram) (`/dev/i2c-1`) are dynamically installed during runtime.

### Container setup

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

For NPIX-RS232, NPIX-RS485 modules support:

To grant access to the serial port the device `/dev/ttyS0` needs to be added to the container. It needs an NPIX module attached during system boot process to be available. (NPIX-RS485 Remark: set GPIO 17 to '1' to activate NPIX-RS485 REV#2 module TX/RX auto direction feature).

For netPI RTE 3 target:

To grant access to the onboard netX industrial network controller the `/dev/spidev0.0` host device needs to be added to the container.

To grant access to the onboard FRAM memory the `/dev/i2c-1` host device needs to be added to the container.

#### Privileged mode

The privileged mode option needs to be activated to lift the standard Docker enforced container limitations. With this setting the container and the applications inside are the getting (almost) all capabilities as if running on the Host directly. 

#### Environment variables

For netPI RTE 3 target only:

The type of field network protocol can be specified that is loaded into netX industrial network controller through the following variable

* **FIELD** with value `pns` to load PROFINET IO device or value `eis` to load EtherNet/IP adapter network protocol

### Container deployment

STEP 1. Open netPI's website in your browser (https).

STEP 2. Click the Docker tile to open the [Portainer.io](http://portainer.io/) Docker management user interface.

STEP 3. Enter the following parameters under *Containers > + Add Container*

Parameter | Value | Remark
:---------|:------ |:------
*Image* | **hilschernetpi/netpi-nodered** |
*Network > Network* | **host** |
*Restart policy* | **always**
*Runtime > Env* | *name* **FIELD** -> *value* **pns** or **eis** | optional, netPI RTE 3
*Runtime > Devices > +add device* | *Host path* **/dev/ttyAMA0** -> *Container path* **/dev/ttyAMA0** | optional, Bluetooth
*Runtime > Devices > +add device* | *Host path* **/dev/vcio** -> *Container path* **/dev/vcio** | optional, Bluetooth
*Runtime > Devices > +add device* | *Host path* **/dev/gpiomem** -> *Container path* **/dev/gpiomem** | optional, DIO, AIU
*Runtime > Devices > +add device* | *Host path* **/dev/spidev0.0** -> *Container path* **/dev/spidev0.0** | optional, Fieldbus
*Runtime > Devices > +add device* | *Host path* **/dev/i2c-1** -> *Container path* **/dev/i2c-1** | optional, FRAM, CAN
*Runtime > Devices > +add device* | *Host path* **/dev/ttyS0** -> *Container path* **/dev/ttyS0** | optional, NPIX serial
*Runtime > Privileged mode* | **On** |

STEP 4. Press the button *Actions > Start/Deploy container*

Pulling the image may take a while (5-10mins). Sometimes it may take too long and a time out is indicated. In this case repeat STEP 4.

### Container access

The container starts Node-RED automatically when started.

Node-RED supports https secured web communication only. Open it in your browser with `https://<netPI-ip-address>:1880` e.g. `https://192.168.0.1:1880`.

The container automatically adapts the netPI Control Panel/User Management setting if found. In this case login with valid user credentials.

### Container tips & tricks

For additional help or information visit the Hilscher Forum at https://forum.hilscher.com/

### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
