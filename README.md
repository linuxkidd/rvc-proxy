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

### rvc_monitor.pl

Listens for RV-C messages on a canbus network, decodes them, and
publishes summary information to an MQTT message broker on the local
host.

Most decoders (e.g. DC_DIMMER_STATUS_3) publish to MQTT and print to
STDOUT an ordered, comma-separated list of values. Newer decoders return
a JSON object containing key-value pairs to eliminate the requirement to
know the order of returned values.

Sample output:
```
2018-03-21 19:34:03.85345,93,1FFDC,GENERATOR_STATUS_1_JSON,{"battvolt":"n/a","load":"n/a","runtime":7,"status":"Stopped"},005E010000FFFFFF
2018-03-21 19:34:03.85933,42,1FFCA,CHARGER_AC_STATUS_1_JSON,1,{"freq":"60.1","gndcur":3,"opengnd":3,"openneut":3,"revpol":3,"rmsc":"n/a","rmsv":"118.0"},013809FFFF0D1EFF
2018-03-21 19:34:03.89226,93,1FFFF,DATE_TIME_STATUS,2000-06-03 14:32:56,n/a,Sunday,000603010E2038FF
2018-03-21 19:34:03.90309,98,1FFBE,AC_LOAD_COMMAND,219,n/a,0.0,Automatic,none,n/a,DBFF006000000000
2018-03-21 19:34:03.90606,93,1FFBF,AC_LOAD_STATUS_JSON,219,{"delay":0,"demandcur":11,"group":"n/a","instance":219,"level":"0.0","mode":"Automatic","presentcur":"n/a","priority":"n/a","variable":"0"},DBFF0060000BFFFF
2018-03-21 19:34:03.95133,42,1FFD7,INVERTER_AC_STATUS_1_JSON,65,{"freq":"60.1","gndcur":3,"opengnd":3,"openneut":3,"revpol":3,"rmsc":"n/a","rmsv":"118.0"},413809FFFF0D1EFF
2018-03-21 19:34:03.99334,42,1FFFD,DC_SOURCE_STATUS_1,House,12.90,0.0,0164020100943577
2018-03-21 19:34:04.01533,42,1FEBD,INVERTER_TEMPERATURE_STATUS,1,98.6,98.6,01C026C026FFFFFF
2018-03-21 19:34:04.05233,42,1FFD7,INVERTER_AC_STATUS_1_JSON,65,{"freq":"60.1","gndcur":3,"opengnd":3,"openneut":3,"revpol":3,"rmsc":"n/a","rmsv":"118.0"},413809FFFF0D1EFF
```

### dc_dimmer.pl

Sends a `DC_DIMMER_COMMAND_2` message (`1FEDB`) to the CAN bus. This is
typically used to control lights, but can also be used to turn other
items on and off, such as a water pump or fan.

### ceiling_fan.pl

Sends a combination of `DC_DIMMER_COMMAND_2` messages (`1FEDB`) to
control the bedroom ceiling fan.

### vent_fan.pl

Sends `DC_DIMMER_COMMAND_2` messages (`1FEDB`) to the CAN bus to control
the ceiling vent lids and fans in Tiffin motorhomes.

Turning fans on and off is handled via a single command, just like
turning a light on or off.

Opening and closing a vent lid requires a pair of reversing commands
with a duration value. For example, to open the galley vent lid on a
2018 Tiffin, the following sequence is sent:

```
Instance 27
Brightness 0
Command Off
Duration 0

Instance 26
Brightness 100%
Command On
Duration 20s
```

To close the galley vent lid, the following sequence is sent:
```
Instance 26
Brightness 0
Command Off
Duration 0

Instance 27
Brightness 100%
Command On
Duration 20s
```

