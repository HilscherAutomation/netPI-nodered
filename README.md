## Node-RED

[![](https://images.microbadger.com/badges/image/hilschernetpi/netpi-nodered:rte3.svg)](https://microbadger.com/images/hilschernetpi/netpi-nodered:rte3 "Node-RED")
[![](https://images.microbadger.com/badges/commit/hilschernetpi/netpi-nodered:rte3.svg)](https://microbadger.com/images/hilschernetpi//netpi-nodered:rte3 "Node-RED")
[![Docker Registry](https://img.shields.io/docker/pulls/hilschernetpi/netpi-nodered.svg)](https://registry.hub.docker.com/u/hilschernetpi/netpi-nodered/)&nbsp;
[![Image last updated](https://img.shields.io/badge/dynamic/json.svg?url=https://api.microbadger.com/v1/images/hilschernetpi/netpi-nodered:rte3&label=Image%20last%20updated&query=$.LastUpdated&colorB=007ec6)](http://microbadger.com/images/hilschernetpi/netpi-nodered:rte3 "Image last updated")&nbsp;

Made for [netPI](https://www.netiot.com/netpi/), the Raspberry Pi 3B Architecture based industrial suited Open Edge Connectivity Ecosystem

### Secured netPI Docker

netPI features a restricted Docker protecting the system software's integrity by maximum. The restrictions are 

* privileged mode is not automatically adding all host devices `/dev/` to a container
* volume bind mounts to rootfs is not supported
* the devices `/dev`,`/dev/mem`,`/dev/sd*`,`/dev/dm*`,`/dev/mapper`,`/dev/mmcblk*` cannot be added to a container

### Container features

The image provided hereunder deploys a container with installed Debian, Node-RED, netPI specific Node-RED nodes and several useful common Node-RED nodes maintained by the community.

Base of the image builds [debian](https://www.balena.io/docs/reference/base-images/base-images/) with installed Internet of Things flow-based programming web-tool [Node-RED](https://nodered.org/).

Additionally the nodes `node-red-contrib-opcua`, `node-red-dashboard`, `node-red-contrib-ibm-watson-iot`, `node-red-contrib-azure-iot-hub`, `node-red-contrib-modbus`, `node-red-contrib-influxdb`, `node-red-contrib-mssql-plus` are installed.

Depending on the available/added devices (/dev/) found during runtime the nodes `node-red-contrib-npix-io (/dev/gpiomem)`, `node-red-contrib-npix-ai (/dev/i2c-1)`, `node-red-contrib-user-leds (/dev/gpiomem)`, `node-red-contrib-npix-leds (/dev/gpiomem)`, `node-red-contrib-generic-ble (/dev/ttyAMA0,/dev/vcio)`, `node-red-node-serialport (/dev/ttyS0)`, `node-red-contrib-canbus (/dev/i2c-1)`, `node-red-contrib-fieldbus (/dev/spidev0.0)`, `node-red-contrib-fram (/dev/i2c-1)` are installed.

### Container setup

#### Port mapping, network mode

The container needs to run in `host` network mode. 

Using this mode makes port mapping unnecessary since all the used container ports (like 1880) are exposed to the host automatically.

#### Host devices

To grant access to the onboard BCM bluetooth chip the `/dev/ttyAMA0` host device needs to be added to the container. 

To prevent the container from failing to load the bluetooth chip with firmware (after soft restart), the chip is physically reset during each container start. To grant access to the reset logic the `/dev/vcio` host device needs to be added to the container.

To grant acccess to the GPIO signals in general the `/dev/gpiomem` host device needs to be added to the container.

To grant access to serial port NPIX expansion modules NPIX-RS232 or NPIX-RS485 the device `/dev/ttyS0` needs to be added to the container. This tty device is only available if an inserted NPIX module has been recognized by netPI during boot process. Else the container will fail to start.(set GPIO 17 to '1' to activate NPIX-RS485 REV#2 module TX/RX auto direction feature).

For netPI RTE 3 target additionally:

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

### Container automated build

The project complies with the scripting based [Dockerfile](https://docs.docker.com/engine/reference/builder/) method to build the image output file. Using this method is a precondition for an [automated](https://docs.docker.com/docker-hub/builds/) web based build process on DockerHub platform.

DockerHub web platform is x86 CPU based, but an ARM CPU coded output file is needed for Raspberry Pi systems. This is why the Dockerfile includes the [balena.io](https://balena.io/blog/building-arm-containers-on-any-x86-machine-even-dockerhub/) steps.

### License

View the license information for the software in the project. As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).
As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

[![N|Solid](http://www.hilscher.com/fileadmin/templates/doctima_2013/resources/Images/logo_hilscher.png)](http://www.hilscher.com)  Hilscher Gesellschaft fuer Systemautomation mbH  www.hilscher.com
