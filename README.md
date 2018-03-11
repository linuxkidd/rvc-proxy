RVC-Proxy
=========

A collection of code to communicate with [RV-C
devices](https://en.wikipedia.org/wiki/RV-C) on a [CAN
bus](https://en.wikipedia.org/wiki/CAN_bus) network.

For more information on the RV-C protocol, please visit
[www.rv-c.com](http://www.rv-c.com/). Download the complete [RV-C
specification](http://www.rv-c.com/?q=node/75) for details on the
commands and their parameters. This PDF file is critical for
understanding how to communicate with RV-C devices.

Prerequisites
-------------

* A computer with a canbus network card configured on interface `can0`.
* An [MQTT](http://mqtt.org/) message broker. We recommend the
  [Mosquitto](https://mosquitto.org/) message broker.

Programs
--------

Our RV-C programs are being added individually after reviewing each.
More will be added over the next few weeks.

`rvc_monitor.pl` - listens for RV-C messages on a canbus network,
decodes them, and publishes summary information to an MQTT message
broker on the local host.

`dc_dimmer.pl` - sends a `DC_DIMMER_COMMAND_2` message (`1FEDB`) to the
CAN bus. This is typically used to control lights, but can also be used
to turn other items on and off, such as a water pump or fan.
