#!/usr/bin/perl -w
#
# Copyright 2018 Wandertech LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

our $printall=1;

use strict;
use Net::MQTT::Simple "localhost";
use JSON;
use feature qw(state);

no strict 'refs';

our %hexcommands=('00'=>'Set Level(delay)','01'=>'On (Duration)','02'=>'On (Delay)','03'=>'Off (Delay)',
		'04'=>'Stop', '05'=>'Toggle', '06'=>'Memory Off', '10'=>'Tilt', '11'=>'Ramp Brightness', '12'=>'Ramp Toggle',
		'13'=>'Ramp Up', '14'=>'Ramp Down', '15'=>'Ramp Up/Down', '21'=>'Lock', '22'=>'Unlock', '31'=>'Flash',
		'32'=>'Flash Momentary', '41'=>'Reverse', '45'=>'Toggle Reverse', '81'=>'Forward', '85'=>'Toggle Forward');

our %DGN_MASTER=(
    '1FFFF'=>['DATE_TIME_STATUS','6.4.2'],
    '1FFFE'=>['SET_DATE_TIME_COMMAND','6.4.3'],
    '1FFFD'=>['DC_SOURCE_STATUS_1','6.5.2'],
    '1FFFC'=>['DC_SOURCE_STATUS_2','6.5.3'],
    '1FFFB'=>['DC_SOURCE_STATUS_3','6.5.4'],
    '1FFFA'=>['COMMUNICATION_STATUS_1','6.6.2'],
    '1FFF9'=>['COMMUNICATION_STATUS_2','6.6.3'],
    '1FFF8'=>['COMMUNICATION_STATUS_3','6.6.4'],
    '1FFF7'=>['WATERHEATER_STATUS','6.9.2'],
    '1FFF6'=>['WATERHEATER_COMMAND','6.9.3'],
    '1FFF5'=>['GAS_SENSOR_STATUS','6.10.2'],
    '1FFF4'=>['CHASSIS_MOBILITY_STATUS','6.11.2'],
    '1FFF3'=>['CHASSIS_MOBILITY_COMMAND','6.11.3'],
    '1FFF2'=>['AAS_CONFIG_STATUS','6.12.2'],
    '1FFF1'=>['AAS_COMMAND','6.12.3'],
    '1FFF0'=>['AAS_STATUS','6.12.4'],
    '1FFEF'=>['AAS_SENSOR_STATUS','6.12.5'],
    '1FFEE'=>['LEVELING_CONTROL_COMMAND','6.13.2'],
    '1FFED'=>['LEVELING_CONTROL_STATUS','6.14.2'],
    '1FFEC'=>['LEVELING_JACK_STATUS','6.14.3'],
    '1FFEB'=>['LEVELING_SENSOR_STATUS','6.14.4'],
    '1FFEA'=>['HYDRAULIC_PUMP_STATUS','6.14.5'],
    '1FFE9'=>['LEVELING_AIR_STATUS','6.14.7'],
    '1FFE8'=>['SLIDE_STATUS','6.15.1'],
    '1FFE7'=>['SLIDE_COMMAND','6.15.2'],
    '1FFE6'=>['SLIDE_SENSOR_STATUS','6.15.3'],
    '1FFE5'=>['SLIDE_MOTOR_STATUS','6.15.4'],
    '1FFE4'=>['FURNACE_STATUS','6.16.2'],
    '1FFE3'=>['FURNACE_COMMAND','6.16.3'],
    '1FFE2'=>['THERMOSTAT_STATUS_1','6.17.2'],
    '1FFE1'=>['AIR_CONDITIONER_STATUS','6.18.5'],
    '1FFE0'=>['AIR_CONDITIONER_COMMAND','6.18.3'],
    '1FFDF'=>['GENERATOR_AC_STATUS_1','6.19.3'],
    '1FFDE'=>['GENERATOR_AC_STATUS_2','6.19.4'],
    '1FFDD'=>['GENERATOR_AC_STATUS_3','6.19.5'],
    '1FFDC'=>['GENERATOR_STATUS_1','6.19.16'],
    '1FFDB'=>['GENERATOR_STATUS_2','6.19.17'],
    '1FFDA'=>['GENERATOR_COMMAND','6.19.18'],
    '1FFD9'=>['GENERATOR_START_CONFIG_STATUS','6.19.19'],
    '1FFD8'=>['GENERATOR_START_CONFIG_COMMAND','6.19.20'],
    '1FFD7'=>['INVERTER_AC_STATUS_1','6.20.3'],
    '1FFD6'=>['INVERTER_AC_STATUS_2','6.20.4'],
    '1FFD5'=>['INVERTER_AC_STATUS_3','6.20.5'],
    '1FFD4'=>['INVERTER_STATUS','6.20.6'],
    '1FFD3'=>['INVERTER_COMMAND','6.20.9'],
    '1FFD2'=>['INVERTER_CONFIGURATION_STATUS_1','6.20.10'],
    '1FFD1'=>['INVERTER_CONFIGURATION_STATUS_2','6.20.11'],
    '1FFD0'=>['INVERTER_CONFIGURATION_COMMAND_1','6.20.13'],
    '1FFCF'=>['INVERTER_CONFIGURATION_COMMAND_2','6.20.14'],
    '1FFCE'=>['INVERTER_STATISTICS_STATUS','6.20.16'],
    '1FFCD'=>['INVERTER_APS_STATUS','6.20.17'],
    '1FFCC'=>['INVERTER_DCBUS_STATUS','6.20.18'],
    '1FFCB'=>['INVERTER_OPS_STATUS','6.20.19'],
    '1FFCA'=>['CHARGER_AC_STATUS_1','6.21.3'],
    '1FFC9'=>['CHARGER_AC_STATUS_2','6.21.4'],
    '1FFC8'=>['CHARGER_AC_STATUS_3','6.21.5'],
    '1FFC7'=>['CHARGER_STATUS','6.21.6'],
    '1FFC6'=>['CHARGER_CONFIGURATION_STATUS','6.21.9'],
    '1FFC5'=>['CHARGER_COMMAND','6.21.10'],
    '1FFC4'=>['CHARGER_CONFIGURATION_COMMAND','6.21.11'],
    '1FFC3'=>['reserved',''],
    '1FFC2'=>['CHARGER_APS_STATUS','6.21.21'],
    '1FFC1'=>['CHARGER_DCBUS_STATUS','6.21.22'],
    '1FFC0'=>['CHARGER_OPS_STATUS','6.21.23'],
    '1FFBF'=>['AC_LOAD_STATUS','6.23.2'],
    '1FFBE'=>['AC_LOAD_COMMAND','6.23.4'],
    '1FFBD'=>['DC_LOAD_STATUS','6.24.2'],
    '1FFBC'=>['DC_LOAD_COMMAND','6.24.4'],
    '1FFBB'=>['DC_DIMMER_STATUS_1','6.25.2'],
    '1FFBA'=>['DC_DIMMER_STATUS_2','6.25.3'],
    '1FFB9'=>['DC_DIMMER_COMMAND','6.25.5'],
    '1FFB8'=>['DIGITAL_INPUT_STATUS','6.26.2'],
    '1FFB7'=>['TANK_STATUS','6.29.2'],
    '1FFB6'=>['TANK_CALIBRATION_COMMAND','6.29.3'],
    '1FFB5'=>['TANK_GEOMETRY_STATUS','6.29.4'],
    '1FFB4'=>['TANK_GEOMETRY_COMMAND','6.29.5'],
    '1FFB3'=>['WATER_PUMP_STATUS','6.30.2'],
    '1FFB2'=>['WATER_PUMP_COMMAND','6.30.3'],
    '1FFB1'=>['AUTOFILL_STATUS','6.31.2'],
    '1FFB0'=>['AUTOFILL_COMMAND','6.31.3'],
    '1FFAF'=>['WASTEDUMP_STATUS','6.32.2'],
    '1FFAE'=>['WASTEDUMP_COMMAND','6.32.3'],
    '1FFAD'=>['ATS_AC_STATUS_1','6.33.2'],
    '1FFAC'=>['ATS_AC_STATUS_2','6.33.2'],
    '1FFAB'=>['ATS_AC_STATUS_3','6.33.2'],
    '1FFAA'=>['ATS_STATUS','6.33.4'],
    '1FFA9'=>['ATS_COMMAND','6.33.5'],
    '1FFA8'=>['reserved',''],
    '1FFA7'=>['reserved',''],
    '1FFA6'=>['reserved',''],
    '1FFA5'=>['WEATHER_STATUS_1','6.34.2'],
    '1FFA4'=>['WEATHER_STATUS_2','6.34.3'],
    '1FFA3'=>['ALTIMETER_STATUS','6.34.4'],
    '1FFA2'=>['ALTIMETER_COMMAND','6.34.5'],
    '1FFA1'=>['WEATHER_CALIBRATE_COMMAND','6.34.6'],
    '1FFA0'=>['COMPASS_BEARING_STATUS','6.35.2'],
    '1FF9F'=>['COMPASS_CALIBRATE_COMMAND','6.35.3'],
    '1FF9E'=>['reserved (formerly BRIDGE_COMMAND)','6.8'],
    '1FF9D'=>['reserved (formerly BRIDGE_DGN_LIST)','6.8'],
    '1FF9C'=>['THERMOSTAT_AMBIENT_STATUS','6.17.11'],
    '1FF9B'=>['HEAT_PUMP_STATUS','6.18.4'],
    '1FF9A'=>['HEAT_PUMP_COMMAND','6.18.5'],
    '1FF99'=>['CHARGER_EQUALIZATION_STATUS','6.21.18'],
    '1FF98'=>['CHARGER_EQUALIZATION_CONFIGURATION_STATUS','6.21.19'],
    '1FF97'=>['CHARGER_EQUALIZATION_CONFIGURATION_COMMAND','6.21.20'],
    '1FF96'=>['CHARGER_CONFIGURATION_STATUS_2','6.21.12'],
    '1FF95'=>['CHARGER_CONFIGURATION_COMMAND_2','6.21.13'],
    '1FF94'=>['GENERATOR_AC_STATUS_4','6.19.6'],
    '1FF93'=>['GENERATOR_ACFAULT_CONFIGURATION_STATUS_1','6.19.7'],
    '1FF92'=>['GENERATOR_ACFAULT_CONFIGURATION_STATUS_2','6.19.7'],
    '1FF91'=>['GENERATOR_ACFAULT_CONFIGURATION_COMMAND_1','6.19.7'],
    '1FF90'=>['GENERATOR_ACFAULT_CONFIGURATION_COMMAND_2','6.19.7'],
    '1FF8F'=>['INVERTER_AC_STATUS_4','6.20.6'],
    '1FF8E'=>['INVERTER_ACFAULT_CONFIGURATION_STATUS_1','6.20.7'],
    '1FF8D'=>['INVERTER_ACFAULT_CONFIGURATION_STATUS_2','6.20.7'],
    '1FF8C'=>['INVERTER_ACFAULT_CONFIGURATION_COMMAND_1','6.20.7'],
    '1FF8B'=>['INVERTER_ACFAULT_CONFIGURATION_COMMAND_2','6.20.7'],
    '1FF8A'=>['CHARGER_AC_STATUS_4','6.21.6'],
    '1FF89'=>['CHARGER_ACFAULT_CONFIGURATION_STATUS_1','6.21.7'],
    '1FF88'=>['CHARGER_ACFAULT_CONFIGURATION_STATUS_2','6.21.7'],
    '1FF87'=>['CHARGER_ACFAULT_CONFIGURATION_COMMAND_1','6.21.7'],
    '1FF86'=>['CHARGER_ACFAULT_CONFIGURATION_COMMAND_2','6.21.7'],
    '1FF85'=>['ATS_AC_STATUS_4','6.33.2'],
    '1FF84'=>['ATS_ACFAULT_CONFIGURATION_STATUS_1','6.33.3'],
    '1FF83'=>['ATS_ACFAULT_CONFIGURATION_STATUS_2','6.33.3'],
    '1FF82'=>['ATS_ACFAULT_CONFIGURATION_COMMAND_1','6.33.3'],
    '1FF81'=>['ATS_ACFAULT_CONFIGURATION_COMMAND_2','6.33.3'],
    '1FF80'=>['GENERATOR_DEMAND_STATUS','6.36.2'],
    '1FEFF'=>['GENERATOR_DEMAND_COMMAND','6.36.3'],
    '1FEFE'=>['AGS_CRITERION_STATUS','6.36.4'],
    '1FEFD'=>['AGS_CRITERION_COMMAND','6.36.6'],
    '1FEFC'=>['FLOOR_HEAT_STATUS','6.37.2'],
    '1FEFB'=>['FLOOR_HEAT_COMMAND','6.37.3'],
    '1FEFA'=>['THERMOSTAT_STATUS_2','6.17.3'],
    '1FEF9'=>['THERMOSTAT_COMMAND_1','6.17.4'],
    '1FEF8'=>['THERMOSTAT_COMMAND_2','6.17.5'],
    '1FEF7'=>['THERMOSTAT_SCHEDULE_STATUS_1','6.17.7'],
    '1FEF6'=>['THERMOSTAT_SCHEDULE_STATUS_2','6.17.8'],
    '1FEF5'=>['THERMOSTAT_SCHEDULE_COMMAND_1','6.17.9'],
    '1FEF4'=>['THERMOSTAT_SCHEDULE_COMMAND_2','6.17.10'],
    '1FEF3'=>['AWNING_STATUS','6.39.2'],
    '1FEF2'=>['AWNING_COMMAND','6.39.3'],
    '1FEF1'=>['TIRE_RAW_STATUS','6.38.2'],
    '1FEF0'=>['TIRE_STATUS','6.38.3'],
    '1FEEF'=>['TIRE_SLOW_LEAK_ALARM','6.38.4'],
    '1FEEE'=>['TIRE_TEMPERATURE_CONFIGURATION_STATUS','6.38.6'],
    '1FEED'=>['TIRE_PRESSURE_CONFIGURATION_STATUS','6.38.7'],
    '1FEEC'=>['TIRE_PRESSURE_CONFIGURATION_COMMAND','6.38.8'],
    '1FEEB'=>['TIRE_TEMPERATURE_CONFIGURATION_COMMAND','6.38.8'],
    '1FEEA'=>['TIRE_ID_STATUS','6.38.10'],
    '1FEE9'=>['TIRE_ID_COMMAND','6.38.11'],
    '1FEE8'=>['INVERTER_DC_STATUS','6.20.20'],
    '1FEE7'=>['GENERATOR_DEMAND_CONFIGURATION_STATUS','6.36.7'],
    '1FEE6'=>['GENERATOR_DEMAND_CONFIGURATION_COMMAND','6.36.8'],
    '1FEE5'=>['LOCK_STATUS','6.41.2'],
    '1FEE4'=>['LOCK_COMMAND','6.41.3'],
    '1FEE3'=>['WINDOW_STATUS','6.41.4'],
    '1FEE2'=>['WINDOW_COMMAND','6.41.5'],
    '1FEE1'=>['DC_MOTOR_CONTROL_COMMAND','6.28.3'],
    '1FEE0'=>['DC_MOTOR_CONTROL_STATUS','6.28.2'],
    '1FEDF'=>['WINDOW_SHADE_CONTROL_COMMAND','6.40.3'],
    '1FEDE'=>['WINDOW_SHADE_CONTROL_STATUS','6.40.2'],
    '1FEDD'=>['AC_LOAD_STATUS_2','6.23.3'],
    '1FEDC'=>['DC_LOAD_STATUS_2','6.24.3'],
    '1FEDB'=>['DC_DIMMER_COMMAND_2','6.25.6'],
    '1FEDA'=>['DC_DIMMER_STATUS_3','6.25.4'],
    '1FED9'=>['GENERIC_INDICATOR_COMMAND','6.27.2'],
    '1FED8'=>['GENERIC_CONFIGURATION_STATUS','6.3.2'],
    '1FED7'=>['GENERIC_INDICATOR_STATUS','6.27.1.1'],
    '1FED6'=>['MFG_SPECIFIC_CLAIM_REQUEST','3.3.4'],
    '1FED5'=>['AGS_DEMAND_CONFIGURATION_STATUS','6.36.7'],
    '1FED4'=>['AGS_DEMAND_CONFIGURATION_COMMAND','6.36.8'],
    '1FED3'=>['GPS_STATUS','6.42.3'],
    '1FED2'=>['AGS_CRITERION_STATUS_2','6.36.5'],
    '1FED1'=>['SUSPENSION_AIR_PRESSURE_STATUS','6.12.6'],
    '1FED0'=>['PGN_DC_DISCONNECT_STATUS','6.43.2'],
    '1FECF'=>['PGN_DC_DISCONNECT_COMMAND','6.43.3'],
    '1FECE'=>['INVERTER_CONFIGURATION_STATUS_3','6.20.12'],
    '1FECD'=>['INVERTER_CONFIGURATION_COMMAND_3','6.20.15'],
    '1FECC'=>['CHARGER_CONFIGURATION_STATUS_3','6.21.14'],
    '1FECB'=>['CHARGER_CONFIGURATION_COMMAND_3','6.21.15'],
    '1FECA'=>['DM-RV','3.2.5'],
    '1FEC9'=>['DC_SOURCE_STATUS_4','6.5.5'],
    '1FEC8'=>['DC_SOURCE_STATUS_5','6.5.6'],
    '1FEC7'=>['DC_SOURCE_STATUS_6','6.5.7'],
    '1FEC6'=>['GENERATOR_DC_STATUS_1','6.19.9'],
    '1FEC5'=>['GENERATOR_DC_CONFIGURATION_STATUS','6.19.10'],
    '1FEC4'=>['GENERATOR_DC_COMMAND','6.19.11'],
    '1FEC3'=>['GENERATOR_DC_CONFIGURATION_COMMAND','6.19.12'],
    '1FEC2'=>['GENERATOR_DC_EQUALIZATION_STATUS','6.19.13'],
    '1FEC1'=>['GENERATOR_DC_EQUALIZATION_CONFIGURATION_STATUS','6.19.14'],
    '1FEC0'=>['GENERATOR_DC_EQUALIZATION_CONFIGURATION_COMMAND','6.19.15'],
    '1FEBF'=>['CHARGER_CONFIGURATION_STATUS_4','6.21.16'],
    '1FEBE'=>['CHARGER_CONFIGURATION_COMMAND_4','6.21.17'],
    '1FEBD'=>['INVERTER_TEMPERATURE_STATUS','6.20.21'],
    '1FEBC'=>['HYDRAULIC_PUMP_COMMAND','6.14.6'],
    '1FEBB'=>['GENERIC_AC_STATUS_1','6.22.2'],
    '1FEBA'=>['GENERIC_AC_STATUS_2','6.22.3'],
    '1FEB9'=>['GENERIC_AC_STATUS_3','6.22.4'],
    '1FEB8'=>['GENERIC_AC_STATUS_4','6.22.5'],
    '1FEB7'=>['GENERIC_ACFAULT_CONFIGURATION_STATUS_1','6.22.6'],
    '1FEB6'=>['GENERIC_ACFAULT_CONFIGURATION_STATUS_2','6.22.6'],
    '1FEB5'=>['GENERIC_ACFAULT_CONFIGURATION_COMMAND_1','6.22.6'],
    '1FEB4'=>['GENERIC_ACFAULT_CONFIGURATION_COMMAND_2','6.22.6'],
    '1FEB3'=>['SOLAR_CONTROLLER_STATUS_1','6.46.2'],
    '1FEB2'=>['SOLAR_CONTROLLER_CONFIGURATION','6.46.3'],
    '1FEB1'=>['SOLAR_CONTROLLER_COMMAND','6.46.4'],
    '1FEB0'=>['SOLAR_CONTROLLER_CONFIGURATION_COMMAND','6.46.5'],
    '1FEAF'=>['SOLAR_EQUALIZATION_STATUS','6.46.6'],
    '1FEAE'=>['SOLAR_EQUALIZATION_CONFIGURATION_STATUS','6.46.7'],
    '1FEAD'=>['SOLAR_EQUALIZATION_CONFIGURATION_COMMAND','6.46.8'],
    '17F'=>['GENERAL_RESET','6.2.3'],
    '17E'=>['TERMINAL','6.2.2'],
    '17D'=>['DOWNLOAD','6.2.3'],
    '17C'=>['INSTANCE_ASSIGNMENT','6.2.4'],
    '17B'=>['INSTANCE_STATUS','6.2.4'],
    '0FECA'=>['DM_1','3.2.5.1b'],
    '10FFD'=>['DC_SOURCE_STATUS_SPYDER', ''],
);


our %dc_dimmer_status_3=();

our $lastcleanup=time;
our $cleanup_threshold=3;  # number of seconds of no-update to consider a load off.
our $reset_timer=0;
our $reset_count=0;

for(my $i=0;$i<256;$i++) {
	publish "DC_DIMMER_STATUS_3/$i" => "3,0,$lastcleanup";
}

if ( scalar(@ARGV) ) {
	if ( -e $ARGV[0] ) {
		open FILE,'<', $ARGV[0] or die("Cannot open ".$ARGV[0].": ".$!."\n");
		while(our $char=<FILE>) {
			processPacket();
		}
	} else {
		die("File does not exist: ".$ARGV[0]."\n");
	}
} else {
	open FILE,'candump -ta can0 |' or die("Cannot start candump " . $! ."\n");

	while(my $line=<FILE>) {
		chomp($line);
		my @line_parts=split(' ',$line);
		my $pkttime  = $line_parts[0];
		$pkttime     =~ s/[^0-9\.]//g;
		my $binCanId = sprintf("%b", hex($line_parts[2]));
		my $prio     = sprintf(  "%X", oct("0b".substr( $binCanId,  0,  3)));
		my $dgn      = sprintf("%05X", oct("0b".substr( $binCanId,  4, 17)));
		my $srcAD    = sprintf("%02X", oct("0b".substr( $binCanId, 21,  8)));
		my $pckts    = $line_parts[3];
		$pckts       =~ s/[^0-9]//g;
		my $data     = '';
		for (my $i=4;$i<scalar(@line_parts);$i++) {
			$data.=$line_parts[$i];
		}
		our $char="$pkttime,$prio,$dgn,$srcAD,$pckts,$data";
		processPacket();
		if($reset_timer!=0 && $pkttime-$reset_timer>3) {
			publish "GLOBAL/MESSAGE" => "Reset timed out." if($reset_count>2);
			$reset_timer=0;
			$reset_count=0;
		}
		if((time-$lastcleanup)>1) {
			cleanup();
		}
	}
	close FILE;
}

sub processPacket {
	our $char;
	our $printall;
	if ($char) {
		$char =~ s/\xd//g;
		our ($pkttime,$prio,$dgn,$src,$pkts,$data)=split(',',$char);
		our $partsec=($pkttime-int($pkttime))*100000;
		our $dgnHi=substr($dgn,0,3) if (defined($dgn));
		if (defined($dgn) && defined(&{"decode_$dgn"})) {
			our @bytes = $data =~ m/(..?)/sg;
 			my $decoded=&{"decode_$dgn"};

			if($decoded) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($pkttime);
				$year+=1900; $mon++;
				printf("%4d-%02d-%02d %02d:%02d:%02d.%05d,%s,%s,%s\n",$year,$mon,$mday,$hour,$min,$sec,$partsec,$src,$decoded,join('',@bytes)) if($printall);
			}
		} elsif(defined($dgn) && defined(&{"decode_$dgnHi"})) {
			our @bytes = $data =~ m/(..?)/sg;
 			my $decoded=&{"decode_$dgnHi"};

			if($decoded) {
				my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($pkttime);
				$year+=1900; $mon++;
				printf("%4d-%02d-%02d %02d:%02d:%02d.%05d,%s,%s,%s\n",$year,$mon,$mday,$hour,$min,$sec,$partsec,$src,$decoded,join('',@bytes)) if($printall);
			}
		} elsif(defined($prio) && $prio ne 'prio' && defined($data)) {
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($pkttime);
			$year+=1900; $mon++;
			printf("%4d-%02d-%02d %02d:%02d:%02d.%05d,%s,%s,UNKNOWN,%s\n",$year,$mon,$mday,$hour,$min,$sec,$partsec,$src,$dgn,$data) if($printall);
		}
	}
}

exit(0);

sub cleanup {
	our %dc_dimmer_status_3;
	our $lastcleanup;
	our $cleanup_threshold;
	my $starttime=time;
	foreach my $key (keys %dc_dimmer_status_3) {
		if(($starttime-$dc_dimmer_status_3{$key}[2])>$cleanup_threshold && $dc_dimmer_status_3{$key}[1]>0) { # No update in $threshold seconds and last status was not off
			delete $dc_dimmer_status_3{$key};
			publish "DC_DIMMER_STATUS_3/$key" => "3,0,".time;
		}
	}
	$lastcleanup=$starttime;
}


sub tempU16 {
	my ($data)=@_;
	my $temp='n/a';
	$temp=sprintf("%0.1f",tempC2F((hex($data)*0.03125)-273)) if ($data ne 'FFFF');
	return $temp;
}

sub tempU8 {
	my ($data)=@_;
	my $temp='n/a';
	$temp=sprintf("%0.1f",tempC2F(hex($data)-40)) if ($data ne 'FF');
	return $temp;
}

sub tempC2F {
	my ($temp)=@_;
	return ($temp*9/5)+32;
}

sub currentU8 {
	my ($data)=@_;
	return hex($data);
}

sub currentU16 {
	my ($data)=@_;
	my $current='n/a';
	$current=sprintf("%0.1f",(hex($data)*0.05)-1600) if ($data ne 'FFFF');
	return $current;
}

sub currentU32 {
	my ($data)=@_;
	my $current='n/a';
	$current=sprintf("%0.001f",(hex($data)*0.001)-2000000) if ($data ne 'FFFFFFFF');
	return $current;
}

sub hertzU8 {
	my ($data)=@_;
	return hex($data);
}

sub hertzU16 {
	my ($data)=@_;
	my $freq='n/a';
	$freq=sprintf("%0.1f",(hex($data)/128)) if ($data ne 'FFFF');
	return $freq;
}

sub voltageU8 {
	my ($data)=@_;
	return hex($data);
}

sub voltageU16 {
	my ($data)=@_;
	my $voltage='n/a';
	$voltage=sprintf("%0.1f",(hex($data)*0.05)) if ($data ne 'FFFF');
	return $voltage;
}

sub percentU8 {
	my ($data)=@_;
	my $percent='n/a';
	$percent=sprintf("%0.1f",hex($data)/2) if($data ne 'FF');
	return $percent;
}

sub durationU8 {
	my ($data)=@_;
	my $duration=hex($data);
	$duration=(($duration-240)+4)*60 if($duration > 240 && $duration < 251);
	$duration='n/a' if($duration == 255);
	return $duration;
}

sub groupU8 {
	my ($data)=@_;
	my $bindata=sprintf("%08d",dec2bin(hex($data)));
	return "n/a" if(substr($bindata,0,1)==1);
	return (8-rindex($bindata,'0'));
}

sub binarray {
	my ($data)=@_;
	$data=sprintf("%08s",dec2bin(hex($data)));
	my @binarray= $data =~ m/(.?)/sg;
	pop @binarray;
	return reverse @binarray;
}

sub binarray2 {
	my ($data)=@_;
	$data=sprintf("%08s",dec2bin(hex($data)));
	my @binarray= $data =~ m/(..?)/sg;
	return reverse @binarray;
}

sub binarray4 {
	my ($data)=@_;
	$data=sprintf("%08s",dec2bin(hex($data)));
	my @binarray= $data =~ m/(....?)/sg;
	return reverse @binarray;
}

sub dec2bin {
	my $str = unpack("B32", pack("N", shift));
	$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
	return $str;
}
sub bin2dec {
	return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub decode_0E8 {
	our @bytes;
	our $dgn;
	my @ack_codes=('ACK','NAK','Not acceptable from source','Conditional Failure','Improper Format','Params out of Range','Requires Password','Requires more time','Overriden by User');
	my $ack_code='n/a';
	$ack_code=$ack_codes[hex($bytes[0])] if (defined($ack_codes[hex($bytes[0])]));
	my $instance=hex($bytes[1]);
	my @byte2_bin=binarray4($bytes[2]);
	my $inst_bank=bin2dec($byte2_bin[0]);
	my $dgn_ack=$bytes[7].$bytes[6].$bytes[5];
	return sprintf("%s,ACKNOWLEDGE,%s,%s,%s,%s",$dgn,$ack_code,$instance,$inst_bank,$dgn_ack);

}

sub decode_0EA {
	our @bytes;
	our $dgn;
	my $destaddr=substr($dgn,3,2);
	my $desireddgn=$bytes[2].$bytes[1].$bytes[0];
	return sprintf("%s,ADDRESS_REQUEST,%s,%s",$dgn,$destaddr,$desireddgn);
}

sub decode_0EE {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	my @byte2_bin=binarray4($bytes[2]);
	my $sn=bin2dec($byte2_bin[0]).$bytes[1].$bytes[0];
	my $mancode=$bytes[3].bin2dec($byte2_bin[1]);
	my @byte4_bin=binarray($bytes[4]);
	my $nodeinst=bin2dec($byte4_bin[0].$byte4_bin[1].$byte4_bin[2]);
	my $funcinst=bin2dec($byte4_bin[3].$byte4_bin[4].$byte4_bin[5].$byte4_bin[6].$byte4_bin[7]);
	my $compat1=$bytes[5];
	my $compat2=$bytes[6];
	my @byte7_bin=binarray($bytes[7]);
	my $compat3=bin2dec($byte7_bin[0].$byte7_bin[1].$byte7_bin[2].$byte7_bin[3]);
	my $arbaddrcapable=$byte7_bin[7];
	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$sn,$mancode,$nodeinst,$funcinst,$compat1,$compat2,$compat3,$arbaddrcapable);
}

sub decode_0FECA {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;

	my @byte0_bin=binarray2($bytes[0]);
	my $dsa=$bytes[1];
	my @byte4_bin=binarray($bytes[4]);
	my @byte5_bin=binarray($bytes[5]);
	my $spn=sprintf("%X",bin2dec(dec2bin(hex($bytes[3])).dec2bin(hex($bytes[4])).$byte4_bin[7].$byte4_bin[6].$byte4_bin[5]));
	my $fmi=bin2dec($byte4_bin[4].$byte4_bin[3].$byte4_bin[2].$byte4_bin[1].$byte4_bin[0]);
	pop @byte5_bin;
	my $oc=bin2dec(join('',@byte5_bin));
	my $dsaext='n/a';
	$dsaext=hex($bytes[6]) if ($bytes[6] && $bytes[6] ne 'FF');
	my $bank='n/a';
	if ($bytes[7]) {
		my @byte7_bin=binarray4($bytes[7]);
		$bank=bin2dec($byte7_bin[0]) if (bin2dec($byte7_bin[0]) ne 15);
	}

	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$dsa,$spn,$fmi,$oc,$dsaext,$bank);
}

sub decode_17E {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $mydata='';
	foreach my $mybyte ( @bytes ) {
		$mydata.=pack "H*",$mybyte if($mybyte ne 'FF');
	}
	retain $DGN_MASTER{'17E'}[0]."/0" => "$mydata,$pkttime";
	return sprintf("%s,%s,%s",$dgn,$DGN_MASTER{'17E'}[0],$mydata);
}

sub decode_1FEBD {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $instance=hex($bytes[0]);
	my $fettemp=tempU16($bytes[2].$bytes[1]);
	my $transtemp=tempU16($bytes[4].$bytes[3]);
	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$fettemp,$transtemp,$pkttime";
	return sprintf("%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$fettemp,$transtemp);
}

sub decode_1FED8 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	return sprintf("%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],join('',@bytes));
}

sub decode_1FEE8 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $instance=hex($bytes[0]);
	my $dcv=voltageU16($bytes[2].$bytes[1]);
	my $dcc=currentU16($bytes[4].$bytes[3]);
	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$dcv,$dcc,$pkttime";
	return sprintf("%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$dcv,$dcc);
}

sub decode_1FF87 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $instance=hex($bytes[0]);
	my $elv=hex($bytes[1]);
	my $lv=hex($bytes[2]);
	my $hv=hex($bytes[3]);
	my $ehv=hex($bytes[4]);
	my $qualt=hex($bytes[5]);
	my @bypass_data=binarray2($bytes[6]);
	my $bypass=$bypass_data[0];
	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$elv,$lv,$hv,$ehv,$qualt,$bypass,$pkttime";
	return sprintf("%s,%s,%s,%s,%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$elv,$lv,$hv,$ehv,$qualt,$bypass);
}

sub decode_1FF89 {
	decode_1FF87();
}

sub decode_1FF95 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $instance=hex($bytes[0]);
	my $maxcc=hex($bytes[1]);
	my $crlp=hex($bytes[2]); # Charge Rate Limit as Percent of Bank Size
	my $shorebreaker=hex($bytes[3]);
	my $defbatttemp=tempC2F(hex($bytes[4]));
	my $rechvolts=hex($bytes[6].$bytes[5]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$maxcc,$crlp,$shorebreaker,$defbatttemp,$rechvolts,$pkttime";
	return sprintf("%s,%s,%s,%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$maxcc,$crlp,$shorebreaker,$defbatttemp,$rechvolts);

}

sub decode_1FF96 {
	decode_1FF95();
}

sub decode_1FF97 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my $instance=hex($bytes[0]);
	my $ev=hex($bytes[2].$bytes[1]);
	my $et=hex($bytes[4].$bytes[3]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$ev,$et,$pkttime";
	return sprintf("%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$ev,$et);
}

sub decode_1FF98 {
	decode_1FF97();
}

sub decode_1FFAB {
  our @bytes;
  our $dgn;
  our $pkttime;
  our %DGN_MASTER;
  my @iots=('Input','Output');
  my @sources=('Shore','Generator');
  my @legs=('Leg1','Leg2');
  my @waveforms=('true sine','modified sine');
  my @phasestatuses=('nocomp','in phase','180d out');

  my $name = $DGN_MASTER{$dgn}[0];
  my @byte0_bin=binarray($bytes[0]);
  my $instance=bin2dec($byte0_bin[2].$byte0_bin[1].$byte0_bin[0]);
  my $iot=$iots[$byte0_bin[3]];
  my $source=$sources[$byte0_bin[6]];
  my $leg=$legs[$byte0_bin[7]];

  my @byte1_bin=binarray($bytes[0]);
  my $waveform=$waveforms[$byte1_bin[0]];
  my $phasestatus='n/a';
  $phasestatus=$phasestatuses[bin2dec($byte1_bin[5].$byte1_bin[4].$byte1_bin[3].$byte1_bin[2])] if($phasestatuses[bin2dec($byte1_bin[5].$byte1_bin[4].$byte1_bin[3].$byte1_bin[2])]);
  my $realpower=hex($bytes[3].$bytes[2]);
  my $reactpower=hex($bytes[5].$bytes[4]);
  my $harmdist=percentU8($bytes[6]);
  my $compleg=hex($bytes[7]);

  my $result = JSON->new->utf8->canonical->encode({
    instance => $instance, iotype => $iot, source => $source, leg => $leg,
    waveform => $waveform, phase => $phasestatus, realpower => $realpower,
    reactivepower => $reactpower, harmdist => $harmdist, compleg => $compleg
  });

  retain "${name}_JSON/$instance" => $result;
  return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFAC {
  our @bytes;
  our $dgn;
  our $pkttime;
  our %DGN_MASTER;
  my @iots=('Input','Output');
  my @sources=('Shore','Generator');
  my @legs=('Leg1','Leg2');

  my $name = $DGN_MASTER{$dgn}[0];
  my @byte0_bin=binarray($bytes[0]);
  my $instance=bin2dec($byte0_bin[2].$byte0_bin[1].$byte0_bin[0]);
  my $iot=$iots[$byte0_bin[3]];
  my $source=$sources[$byte0_bin[6]];
  my $leg=$legs[$byte0_bin[7]];

  my $peakv=voltageU16($bytes[2].$bytes[1]);
  my $peakc=currentU16($bytes[4].$bytes[3]);
  my $groundc=currentU16($bytes[6].$bytes[5]);
  my $capacity=currentU8($bytes[7]);

  my $result = JSON->new->utf8->canonical->encode({
    instance => $instance, iotype => $iot, source => $source, leg => $leg,
    peakv => $peakv, peakc => $peakc, groundc => $groundc, capacity => $capacity
  });

  retain "${name}_JSON/$instance" => $result;
  return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFAD {
  our @bytes;
  our $dgn;
  our $pkttime;
  our %DGN_MASTER;
  my @iots=('Input','Output');
  my @sources=('Shore','Generator');
  my @legs=('Leg1','Leg2');
  my @faults=('Ok','Fault');

  my $name = $DGN_MASTER{$dgn}[0];
  my @byte0_bin=binarray($bytes[0]);
  my $instance=bin2dec($byte0_bin[2].$byte0_bin[1].$byte0_bin[0]);
  my $iot=$iots[$byte0_bin[3]];
  my $source=$sources[$byte0_bin[6]];
  my $leg=$legs[$byte0_bin[7]];

  my $rmsv=voltageU16($bytes[2].$bytes[1]);
  my $rmsc=currentU16($bytes[4].$bytes[3]);
  my $freq=hertzU16($bytes[6].$bytes[5]);
  my @byte7_bin=binarray2($bytes[7]);
  my $opengnd=$faults[$byte7_bin[0]];
  my $opennut=$faults[$byte7_bin[1]];
  my $revpol=$faults[$byte7_bin[2]];
  my $gndcur=$faults[$byte7_bin[3]];

  my $result = JSON->new->utf8->canonical->encode({
    instance => $instance, iotype => $iot, source => $source, leg => $leg,
    rmsv => $rmsv, rmsc => $rmsc, freq => $freq, opengnd => $opengnd,
    openneut => $opennut, revpol => $revpol, gndcur => $gndcur
  });

  retain "${name}_JSON/$instance" => $result;
  return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFBE {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;

	my %modes=('00'=>'Automatic','01'=>'Manual');
	my %interlocks=('00'=>'none','01'=>'Interlock A','10'=>'Interlock B');
	my %priorities=('0000'=>'Highest','1101'=>'Lowest','1110'=>'Error','1111'=>'n/a');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $deslevel=percentU8($bytes[2]);
	my @byte3_bin=binarray($bytes[3]);
	my $mode='n/a';
	$mode=$modes{$byte3_bin[1].$byte3_bin[0]} if($modes{$byte3_bin[1].$byte3_bin[0]});
	my $interlock=$interlocks{$byte3_bin[3].$byte3_bin[2]};
	my $priority='n/a';
	$priority=$priorities{$byte3_bin[7].$byte3_bin[6].$byte3_bin[5].$byte3_bin[4]} if($priorities{$byte3_bin[7].$byte3_bin[6].$byte3_bin[5].$byte3_bin[4]});

	retain $DGN_MASTER{$dgn}[0]."/".$instance => "$instance,$group,$deslevel,$mode,$interlock,$priority,$pkttime";
	return sprintf("%s,%s,%s,%s,%s,%s,%s,%s",$dgn,$DGN_MASTER{$dgn}[0],$instance,$group,$deslevel,$mode,$interlock,$priority);
}

sub decode_1FFBF {
  our @bytes;
  our $dgn;
  our $pkttime;
  our %DGN_MASTER;

  my %modes=('00'=>'Automatic','01'=>'Manual');
  my %priorities=('0000'=>'Highest','1101'=>'Lowest','1110'=>'Error','1111'=>'n/a');

  my $name = $DGN_MASTER{$dgn}[0];
  my $instance=hex($bytes[0]);
  my $group=groupU8($bytes[1]);
  my $level=percentU8($bytes[2]);
  my @byte3_bin=binarray($bytes[3]);
  my $mode='n/a';
  $mode=$modes{$byte3_bin[1].$byte3_bin[0]} if($modes{$byte3_bin[1].$byte3_bin[0]});
  my $variable=sprintf("%d",$byte3_bin[3].$byte3_bin[2]);
  my $priority='n/a';
  $priority=$priorities{$byte3_bin[7].$byte3_bin[6].$byte3_bin[5].$byte3_bin[4]} if($priorities{$byte3_bin[7].$byte3_bin[6].$byte3_bin[5].$byte3_bin[4]});
  my $delay=durationU8($bytes[4]);
  my $demcur=currentU8($bytes[5]);
  my $prescur=currentU16($bytes[7].$bytes[6]);

  my $result = JSON->new->utf8->canonical->encode({
    instance => $instance, group => $group, level => $level, mode => $mode,
    variable => $variable, priority => $priority, delay => $delay,
    demandcur => $demcur, presentcur => $prescur
  });

  retain "${name}_JSON/$instance" => $result;
  return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFC4 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my @chargealgo=('Constant Voltage','Constant Current','3-Stage','2-Stage','Trickle');
	my @chargemode=('Stand-Alone','Primary','Secondary','Linked to DC Source');
	my @battypes=('Flooded','Gel','AGM','LiFePo');

	my $instance=hex($bytes[0]);
	my $algo='n/a';
	$algo=$chargealgo[hex($bytes[1])] if($chargealgo[hex($bytes[1])]);
	my $mode='n/a';
	$mode=$chargemode[hex($bytes[2])] if($chargemode[hex($bytes[2])]);
	my @byte3_bin=binarray2($bytes[3]);
	my $batsensepresent=bin2dec($byte3_bin[0]);
	my $chginstline=bin2dec($byte3_bin[1]);
	my $banksize=hex($bytes[5].$bytes[4]);
	my @byte6_bin=binarray4($bytes[6]);
	my $battype='n/a';
	$battype=$battypes[bin2dec($byte6_bin[0])] if($battypes[bin2dec($byte6_bin[0])]);
	my $maxcur=currentU8($bytes[7]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => join(',',$instance,$algo,$mode,$batsensepresent,$chginstline,$banksize,$battype,$maxcur);
	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$instance,$algo,$mode,$batsensepresent,$chginstline,$banksize,$battype,$maxcur);
}

sub decode_1FFC6 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my @chargealgo=('Constant Voltage','Constant Current','3-Stage','2-Stage','Trickle');
	my @chargemode=('Stand-Alone','Primary','Secondary','Linked to DC Source');
	my @battypes=('Flooded','Gel','AGM','LiFePo');

	my $instance=hex($bytes[0]);
	my $algo=$chargealgo[hex($bytes[1])];
	my $mode=$chargemode[hex($bytes[2])];
	my @byte3_bin=binarray2($bytes[3]);
	my $batsensepresent=bin2dec($byte3_bin[0]);
	my $chginstline=bin2dec($byte3_bin[1]);
	my $battype=$battypes[bin2dec($byte3_bin[3].$byte3_bin[2])];
	my $banksize=hex($bytes[5].$bytes[4]);
	my $maxcur=currentU16($bytes[7].$bytes[6]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => join(',',$instance,$algo,$mode,$batsensepresent,$chginstline,$banksize,$battype,$maxcur);
	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$instance,$algo,$mode,$batsensepresent,$chginstline,$banksize,$battype,$maxcur);
}

sub decode_1FFC7 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;
	my @states=('Undef','Do not charge','Bulk','Absorption','Overcharge','Equalize','Float','Constant Volt/Cur');
	my @forces=('Not Forced','Force bulk','Force float');

	my $name = $DGN_MASTER{$dgn}[0];
	my $instance=hex($bytes[0]);
	my $voltage=voltageU16($bytes[2].$bytes[1]);
	my $current=currentU16($bytes[4].$bytes[3]);
	my $curperc=percentU8($bytes[5]);
	my $state='n/a';
	$state=$states[hex($bytes[6])] if($states[hex($bytes[6])]);
	my @byte7_bin=binarray($bytes[7]);
	my $def_state=bin2dec($byte7_bin[1].$byte7_bin[0]);
	my $auto_rech=bin2dec($byte7_bin[3].$byte7_bin[2]);
	my $force_charge='n/a';
	$force_charge=$forces[bin2dec($byte7_bin[7].$byte7_bin[6].$byte7_bin[5].$byte7_bin[4])] if($forces[bin2dec($byte7_bin[7].$byte7_bin[6].$byte7_bin[5].$byte7_bin[4])]);

	my $result = JSON->new->utf8->canonical->encode(
	  { instance => $instance, voltage => $voltage, current => $current, currentpct => $curperc,
	    state => $state, defstate => $def_state, autorecharge => $auto_rech, force => $force_charge }
	);

	retain "${name}_JSON/$instance" => $result;
	return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFCA {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;

  my $name = $DGN_MASTER{$dgn}[0];
	my $instance=hex($bytes[0]);
	my $rmsv=voltageU16($bytes[2].$bytes[1]);
	my $rmsc=currentU16($bytes[4].$bytes[3]);
	my $freq=hertzU16($bytes[6].$bytes[5]);
	my @byte7_bin=binarray2($bytes[7]);
	my $opengnd=bin2dec($byte7_bin[0]);
	my $openneut=bin2dec($byte7_bin[1]);
	my $revpol=bin2dec($byte7_bin[2]);
	my $gndcur=bin2dec($byte7_bin[3]);

  my $result = JSON->new->utf8->canonical->encode(
    { rmsv => $rmsv, rmsc => $rmsc, freq => $freq, opengnd => $opengnd,
      openneut => $openneut, revpol => $revpol, gndcur => $gndcur }
  );

	retain "${name}_JSON/$instance" => $result;
	return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFD0 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;

	my $instance=hex($bytes[0]);
	my $lspt='n/a';
	$lspt=bin2dec($bytes[2].$bytes[1]) if($bytes[2].$bytes[1] ne 'FFFF');
	my $lsi='n/a';
	$lsi=bin2dec($bytes[4].$bytes[3]) if($bytes[4].$bytes[3] ne 'FFFF');
	my $shutdownv=voltageU16($bytes[6].$bytes[5]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => join(',',$lspt,$lsi,$shutdownv);
	return join(',',$dgn, $DGN_MASTER{$dgn}[0],$instance,$lspt,$lsi,$shutdownv);

}

sub decode_1FFD2 {
	our @bytes;
	our $dgn;
	our $pkttime;
	our %DGN_MASTER;

	my $instance=hex($bytes[0]);
	my $lspt='n/a';
	$lspt=hex($bytes[2].$bytes[1]) if($bytes[2].$bytes[1] ne 'FFFF');
	my $lsi='n/a';
	$lsi=hex($bytes[4].$bytes[3]) if($bytes[4].$bytes[3] ne 'FFFF');
	my $shutdownv=voltageU16($bytes[6].$bytes[5]);

	my @byte7_bin=binarray2($bytes[7]);
	my $invenos=bin2dec($byte7_bin[0]);
	my $loadsenseos=bin2dec($byte7_bin[1]);
	my $acpassos=bin2dec($byte7_bin[3]);

	retain $DGN_MASTER{$dgn}[0]."/".$instance => join(',',$lspt,$lsi,$shutdownv,$loadsenseos,$acpassos);
	return join(',',$dgn, $DGN_MASTER{$dgn}[0],$instance,$lspt,$lsi,$shutdownv,$loadsenseos,$acpassos);
}

sub decode_1FFDF {
	decode_1FFCA();
}

sub decode_1FFD7 {
	decode_1FFCA();
}

sub decode_1FED9 {
	our @bytes;
	our $pkttime;
	our $reset_timer;
	our $reset_count;
	my %hexindicator=('00'=>'set both','01'=>'1 off; 2 off','02'=>'1 on; 2 off','03'=>'1 off; 2 on','04'=>'1 on; 2 on','11'=>'ramp','33'=>'alternate');
	my $instance=hex($bytes[0]);
	my $group=hex($bytes[1]);
	my $brightness=percentU8($bytes[2]);
	my @byte3_bin=binarray4($bytes[3]);
	my $bank=bin2dec($byte3_bin[0]);
	my $duration=durationU8($bytes[4]);
	my $command='unknown; ' . $bytes[6];
	$command=$hexindicator{$bytes[6]} if(defined($hexindicator{$bytes[6]}));

	if($instance==255 && $group==126) {
		if($brightness==0 && $reset_timer==0) {
			$reset_timer=$pkttime;
			$reset_count=1;
		} elsif ($reset_timer!=0) {
			$reset_count++;
		}
		if($reset_count>4) {
			if($pkttime-$reset_timer < 3) {
				my $junk=`sudo /CoachProxy/bin/factory_reset.sh`;
			}
			$reset_timer=0;
			$reset_count=0;
		}
		if($reset_count>2) {
			my $reset_diff=int($pkttime-$reset_timer);
			publish "GLOBAL/MESSAGE" => "Reset Count: $reset_count, $reset_diff";
		}
	}

	retain "GENERIC_INDICATOR_COMMAND/$instance" => "$group,".hex($bytes[6]).",$brightness,$pkttime";
	return sprintf("1FED9,GENERIC_INDICATOR_COMMAND,%s,%s,%s,%s,%s",$instance,$group,$brightness,$command,$duration);
}

sub decode_1FEDA {
	our @bytes;
	our %dc_dimmer_status_3;
	our $pkttime;
	our %hexcommands;
	my %binstatus=('00'=>'no','01'=>'yes','11'=>'n/a');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $brightness=percentU8($bytes[2]);
	my @byte3_bin=binarray2($bytes[3]);
	my $locked =$binstatus{$byte3_bin[0]};
	my $overcur=$binstatus{$byte3_bin[1]};
	my $overrid=$binstatus{$byte3_bin[2]};
	my $enabled=$binstatus{$byte3_bin[3]};
	my $duration=durationU8($bytes[4]);
	my $lastcmd='n/a';
	$lastcmd=$hexcommands{$bytes[5]} if (defined($hexcommands{$bytes[5]}));
	my @byte6_bin =binarray2($bytes[6]);
	my $interlock='n/a';
	$interlock=$binstatus{$byte6_bin[0]} if (defined($binstatus{$byte6_bin[0]}));;
	my $loadstat=$binstatus{$byte6_bin[1]};

	retain "DC_DIMMER_STATUS_3/$instance" => $bytes[5].",$brightness,$pkttime";
	$dc_dimmer_status_3{$instance}=[$bytes[5],$brightness,$pkttime];

	return sprintf("1FEDA,DC_DIMMER_STATUS_3,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",$instance,$group,$brightness,$locked,$overcur,$overrid,$enabled,$duration,$lastcmd,$interlock,$loadstat);
}

sub decode_1FEDB {
	our @bytes;
	our $pkttime;
	our %hexcommands;
	my %binstatus=('00'=>'n/a','01'=>'Int A','10'=>'Int B');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $brightness=percentU8($bytes[2]);
	my $command='n/a';
	$command=$hexcommands{$bytes[3]} if (defined($hexcommands{$bytes[3]}));
	my $duration=durationU8($bytes[4]);
	my @byte5_bin = binarray2($bytes[5]);
	my $interlock=$binstatus{$byte5_bin[0]};

	publish "DC_DIMMER_COMMAND_2/$instance" => hex($bytes[3]).",$brightness,$pkttime";

	return sprintf("1FEDB,DC_DIMMER_COMMAND_2,%s,%s,%s,%s,%s,%s",$instance,$group,$brightness,$command,$duration,$interlock);
}


sub decode_1FEDC {
	our @bytes;
	our $pkttime;
	our %hexcommands;

	my %binstatus=('00'=>'no','01'=>'yes','11'=>'n/a');
	my $instance=hex($bytes[0]);
	my @byte1_bin=binarray2($bytes[1]);
	my $locked =$binstatus{$byte1_bin[0]};
	my $overcur=$binstatus{$byte1_bin[1]};
	my $overrid=$binstatus{$byte1_bin[2]};
	my $enabled=$binstatus{$byte1_bin[3]};
	my $lastcmd='unknown: '.$bytes[2];
	$lastcmd=$hexcommands{$bytes[2]} if(defined($hexcommands{$bytes[2]}));
	$bytes[3]=sprintf("%08s",dec2bin(hex($bytes[3])));
	my @byte3_bin = $bytes[3] =~ m/(..?)/sg;
	my $interlock=$binstatus{$byte3_bin[0]};

	retain "DC_LOAD_STATUS_2/$instance" => $lastcmd.",".$pkttime;

	return sprintf("1FEDC,DC_LOAD_STATUS_2,%s,%s,%s,%s,%s,%s,%s",$instance,$locked,$overcur,$overrid,$enabled,$lastcmd,$interlock);

}

sub decode_1FEDE {
	our @bytes;
	my %binmode=('00'=>'Automatic','01'=>'Manual','11'=>'n/a');
	my %binstatus=('00'=>'no','01'=>'yes','11'=>'n/a');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $duty=percentU8($bytes[2]);

	my @byte3_bin= binarray2($bytes[3]);
	my $locked=$binstatus{$byte3_bin[0]};
	my $motion=$binstatus{$byte3_bin[1]};
	my $forward=$binstatus{$byte3_bin[2]};
	my $reverse=$binstatus{$byte3_bin[3]};

	my $duration=durationU8($bytes[4]);
	my $lastcmd=$hexcommands{$bytes[5]};
	my @byte6_bin=binarray2($bytes[6]);
	my $overcurrent=$binstatus{$byte6_bin[0]};
	my $override=$binstatus{$byte6_bin[1]};
	my $disable1=$binstatus{$byte6_bin[2]};
	my $disable2=$binstatus{$byte6_bin[3]};

	return sprintf("1FEDE,WINDOW_SHADE_CONTROL_STATUS,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",$instance,$group,$duty,$locked,$motion,$forward,$reverse,$duration,$lastcmd,$overcurrent,$override,$disable1,$disable2);
}

sub decode_1FEDF {
	our @bytes;
	our %hexcommands;
	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $duty=percentU8($bytes[2]);
	my $command=$hexcommands{$bytes[3]};
	my $duration=durationU8($bytes[4]);
	my @byte5_bin=binarray2($bytes[5]);
	my $interlock=$byte5_bin[0];
	return sprintf("1FEDF,WINDOW_SHADE_CONTROL_COMMAND,%s,%s,%s,%s,%s,%s",$instance,$group,$duty,$command,$duration,$interlock);
}

sub decode_1FEE4 {
	our @bytes;
	my @statuses=('Unlock','Lock');

	my $instance=hex($bytes[0]); # 0 = all
	my @byte1_bin=binarray2($bytes[1]);
	my $status='n/a';
	$status=$statuses[bin2dec($byte1_bin[0])] if (defined($statuses[bin2dec($byte1_bin[0])]));

	return sprintf("1FEE4,LOCK_COMMAND,%s,%s",$instance,$status);
}

sub decode_1FEE5 {
	our @bytes;
	my @statuses=('Unlocked','Locked');

	my $instance=hex($bytes[0]);
	my @byte1_bin=binarray2($bytes[1]);
	my $status='n/a';
	$status=$statuses[bin2dec($byte1_bin[0])] if (defined($statuses[bin2dec($byte1_bin[0])]));

	return sprintf("1FEE5,LOCK_STATUS,%s,%s",$instance,$status);
}

sub decode_1FEF7 {
	our @bytes;
	my @schmodes=('Sleep','Wake','Away','Return');

	my $instance=hex($bytes[0]);
	my $schmode='n/a';
	$schmode=$schmodes[hex($bytes[1])] if(defined($schmodes[hex($bytes[1])]));
	my $starthr='n/a';
	$starthr=hex($bytes[2]) if($bytes[2] ne 'FF');
	my $startmn='n/a';
	$startmn=hex($bytes[3]) if($bytes[3] ne 'FF');
	my $heatset=tempU16($bytes[5].$bytes[4]);
	my $coolset=tempU16($bytes[7].$bytes[6]);
	return sprintf("1FEF7,THERMOSTAT_SCHEDULE_STATUS_1,%s,%s,%s,%s,%s,%s",$instance,$schmode,$starthr,$startmn,$heatset,$coolset);
}

sub decode_1FFB7 {
  our $dgn;
	our @bytes;
	our $pkttime;

	return '' if($bytes[1] eq 'FE');

  my $name = $DGN_MASTER{$dgn}[0];
	my @tanks=('Fresh','Black','Grey','LPG');
	my $instance = hex($bytes[0]);
	my $level = hex($bytes[1])/hex($bytes[2])*100;

	my $result = JSON->new->utf8->canonical->encode({
		instance => $instance, name => $tanks[$instance], level => $level, timestamp => $pkttime
  });

	retain "${name}_JSON/$instance" => $result;
	retain "TANK/$instance" => sprintf("%d,%s",$level,$pkttime); # Note, MQTT name doesn't match DG name

  return "$dgn,${name}_JSON,$instance,$result";
}

# THERMOSTAT_AMBIENT_STATUS
#
# B0 : instance : uint8
# B1-2 : ambient temp : uint16 : deg C
sub decode_1FF9C {
  our $dgn;
  our %DGN_MASTER;
	our @bytes;
	our $pkttime;

  my $name = $DGN_MASTER{$dgn}[0];
	my $instance = hex($bytes[0]);
	my $ambtemp = tempU16($bytes[2].$bytes[1]);

  my $result = JSON->new->utf8->canonical->encode(
    { ambient_temp => $ambtemp, timestamp => $pkttime, unit => 'F' }
  );

	retain "${name}_JSON/$instance" => $result;
  retain "$name/$instance" => sprintf("%s,%s",$ambtemp,$pkttime);

  return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FFB8 {
	our @bytes;
	my @positions=('Off','On');
	my @configurations=('00'=>'Conventional','01'=>'Momentary');

	my $instance=hex($bytes[0]);
	my $position='n/a';
	$position=$positions[hex($bytes[1])] if (defined($positions[hex($bytes[1])]));
	my @byte2_bin=binarray2($bytes[2]);
	my $configuration='n/a';
	$configuration=$configurations[$byte2_bin[0]] if (defined($configurations[$byte2_bin[0]]));
	my $num_positions=hex($bytes[3]); # 2 or more = valid
	my @byte4_bin=binarray4($bytes[4]);
	my $bank='n/a';
	$bank=bin2dec($byte4_bin[0]) if(bin2dec($byte4_bin[0]) < 14);

	return sprintf("1FFB8,DIGITAL_INPUT_STATUS,%s,%s,%s,%s,%s",$instance,$position,$configuration,$num_positions,$bank);
}

sub decode_1FFBC {
	our @bytes;
	our $pkttime;
	our %hexcommands;
	my %binstatus=('00'=>'no','01'=>'yes','11'=>'n/a');
	my %binintlock=('00'=>'n/a','10'=>'Int A','01'=>'Int B');
	my %binmode=('00'=>'Automatic','01'=>'Manual');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $level=percentU8($bytes[2]);
	my @byte3_bin= binarray2($bytes[3]);
	my $opmode=$binmode{$byte3_bin[0]};
	my $interlock='unknown: '.$byte3_bin[1];
	$interlock=$binintlock{$byte3_bin[1]} if(defined($binintlock{$byte3_bin[1]}));
	my $command='unknown: '.$bytes[4];
	$command=$hexcommands{$bytes[4]} if(defined($hexcommands{$bytes[4]}));
	my $duration=durationU8($bytes[5]);

	publish "DC_LOAD_COMMAND/$instance" => "$level,$command,$pkttime";

	return sprintf("1FFBC,DC_LOAD_COMMAND,%s,%s,%s,%s,%s,%s,%s",$instance,$group,$level,$opmode,$interlock,$command,$duration);
}

sub decode_1FFBD {
	our @bytes;
	our $pkttime;
	our %hexcommands;

	my %binstatus=('00'=>'no','01'=>'yes','11'=>'n/a');
	my %binmode=('00'=>'Automatic','01'=>'Manual','11'=>'n/a');

	my $instance=hex($bytes[0]);
	my $group=groupU8($bytes[1]);
	my $level=percentU8($bytes[2]);
	my @byte3_bin= binarray2($bytes[3]);
	my $opmode=$binmode{$byte3_bin[0]};
	my $isvariable=$binstatus{$byte3_bin[1]};
	my $priority='';
	if($byte3_bin[2].$byte3_bin[3] eq '1111') { $priority='No Data' }
	elsif($byte3_bin[2].$byte3_bin[3] eq '1110') { $priority='Error'}
	else { $priority=bin2dec($byte3_bin[2].$byte3_bin[3])}

	my $delay=durationU8($bytes[4]);
	my $maxCurrent=currentU8($bytes[5]);
	my $presentCurrent=currentU16($bytes[7].$bytes[6]);

	retain "DC_LOAD_STATUS/$instance" => "$opmode,$level,$pkttime";

	return sprintf("1FFBD,DC_LOAD_STATUS,%s,%s,%s,%s,%s,%s,%s,%s,%s",$instance,$group,$level,$opmode,$isvariable,$priority,$delay,$maxCurrent,$presentCurrent);

}

sub decode_1FFDC {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	our $pkttime;

	my @statuses=('Stopped','Preheat','Cranking','Running','Priming','Fault','Engine run only','Test mode','Voltage adjust mode','Fault bypass mode','Configuration mode');

	my $name = $DGN_MASTER{$dgn}[0];
	my $status=$statuses[$bytes[0]];
	my $runtime=bin2dec($bytes[4].$bytes[3].$bytes[2].$bytes[1]);
	my $load=percentU8($bytes[5]);
	my $battvolt=voltageU16($bytes[7].$bytes[6]);

	my $result = JSON->new->utf8->canonical->encode({
		status => $status, runtime => $runtime, load => $load, battvolt => $battvolt
	});

	retain "${name}_JSON" => $result;
	retain "$name" => $status.",".$pkttime;

	return "$dgn,${name}_JSON,$result";
	# return sprintf("1FFDC,GENERATOR_STATUS_1,%s,%s,%s,%s",$status,$runtime,$load,$battvolt);
}

sub decode_1FFD3 {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	our $pkttime;
	my @statuses=('Disabled','Invert','AC passthru','APS Only','Load Sense','Waiting to Invert');

	my $instance=hex($bytes[0]);
	my @byte1_bin=binarray2($bytes[1]);
	my $invenabled=bin2dec($byte1_bin[0]);
	my $loadsenseenabled=bin2dec($byte1_bin[0]);
	my $passthruenabled=bin2dec($byte1_bin[0]);

	my @byte7_bin=binarray2($bytes[7]);
	my $invenabledos=bin2dec($byte7_bin[0]);
	my $loadsenseenabledos=bin2dec($byte7_bin[0]);
	my $passthruenabledos=bin2dec($byte7_bin[0]);

	retain $DGN_MASTER{$dgn}[0]."/".hex($bytes[0]) => join(',',$invenabled,$loadsenseenabled,$passthruenabled,$invenabledos,$loadsenseenabledos,$passthruenabledos,$pkttime);

	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$instance,$invenabled,$loadsenseenabled,$passthruenabled,$invenabledos,$loadsenseenabledos,$passthruenabledos);
}

sub decode_1FFD4 {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	our $pkttime;
	my @statuses=('Disabled','Invert','AC passthru','APS Only','Load Sense','Waiting to Invert');
	my %tempsenses=('00'=>'missing','01'=>'present');
	my %loadsenses=('00'=>'disabled','01'=>'enabled');

	my $name = $DGN_MASTER{$dgn}[0];
	my $instance=hex($bytes[0]);
	my $status='n/a';
	$status=$statuses[hex($bytes[1])] if($statuses[hex($bytes[1])]);
	my @byte2_bin=binarray2($bytes[2]);
	my $tempsensepresent='n/a';
	$tempsensepresent=$tempsenses{$byte2_bin[0]} if ($tempsenses{$byte2_bin[0]});
	my $loadsenseenabled='n/a';
	$loadsenseenabled=$loadsenses{$byte2_bin[1]} if ($loadsenses{$byte2_bin[1]});

	my $result = JSON->new->utf8->canonical->encode(
	  { instance => $instance, status => $status, tempsense => $tempsensepresent, loadsense => $loadsenseenabled }
	);

	retain "${name}_JSON/$instance" => $result;
	return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FF9A {
	decode_1FF9B();
}

sub decode_1FF9B {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	our $pkttime;
	my @bytemode=('Auto','Manual');

	my $instance=hex($bytes[0]);
	my $opmode='n/a';
	$opmode=$bytemode[hex($bytes[1])] if($bytemode[hex($bytes[1])]);
	my $maxheatlevel=percentU8($bytes[2]);
	my $heatlevel=percentU8($bytes[3]);
	my $deadband=tempU8($bytes[4]);
	my $secdeadband=tempU8($bytes[5]);

	retain $DGN_MASTER{$dgn}[0]."/".hex($bytes[0]) => join(',',$opmode,$maxheatlevel,$heatlevel,$deadband,$secdeadband,$pkttime);

	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$instance,$opmode,$maxheatlevel,$heatlevel,$deadband,$secdeadband);
}

sub decode_1FFE0 {
	decode_1FFE1();
}

sub decode_1FFE1 {
	our @bytes;
	our $dgn;
	our %DGN_MASTER;
	our $pkttime;
	my @bytemode=('Auto','Manual');

	my $instance=hex($bytes[0]);
	my $opmode='n/a';
	$opmode=$bytemode[hex($bytes[1])] if($bytemode[hex($bytes[1])]);
	my $maxfanspeed=percentU8($bytes[2]);
	my $maxaclevel=percentU8($bytes[3]);
	my $fanspeed=percentU8($bytes[4]);
	my $aclevel=percentU8($bytes[5]);
	my $deadband=tempU8($bytes[6]);
	my $secdeadband=tempU8($bytes[7]);

	retain $DGN_MASTER{$dgn}[0]."/".hex($bytes[0]) => join(',',$opmode,$maxfanspeed,$maxaclevel,$fanspeed,$aclevel,$deadband,$secdeadband,$pkttime);

	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$instance,$opmode,$maxfanspeed,$maxaclevel,$fanspeed,$aclevel,$deadband,$secdeadband);
}


# THERMOSTAT_STATUS_1
#
# B0 : instance : uint8
# B1 b0-3 : Operating mode
#    b4-5 : Fan mode
#    b6-7 : Schedule mode
# B2 : Fan speed
# B3-4 : Setpoint - heat
# B5-6 : Setpoint - cool
sub decode_1FFE2 {
	our $dgn;
	our %DGN_MASTER;
	our @bytes;
	our $pkttime;

	my %binfanmode=('00'=>'Auto','01'=>'On', '11'=>'n/a');
	my %binschmode=('00'=>'Disabled','01'=>'Enabled','10'=>'n/a','11'=>'n/a');
	my %binmode=('0000'=>'Off','0001'=>'Cool','0010'=>'Heat','0011'=>'Auto Heat/Cool','0100'=>'Fan Only','1111'=>'n/a');

	my $name = $DGN_MASTER{$dgn}[0];
	my $instance=hex($bytes[0]);
	my @byte1_bin= binarray2($bytes[1]);
	my $opmode  = 'unknown: ' . $byte1_bin[0].$byte1_bin[1];
	my $fanmode = 'unknown: ' . $byte1_bin[2];
	my $schmode = 'unknown: ' . $byte1_bin[3];
	$opmode=$binmode{$byte1_bin[1].$byte1_bin[0]} if(defined($binmode{$byte1_bin[1].$byte1_bin[0]}));
	$fanmode=$binfanmode{$byte1_bin[2]} if(defined($binfanmode{$byte1_bin[2]}));
	$schmode=$binschmode{$byte1_bin[3]} if(defined($binschmode{$byte1_bin[3]}));
	my $fanspeed=percentU8($bytes[2]);
	my $heatset=tempU16($bytes[4].$bytes[3]);
	my $coolset=tempU16($bytes[6].$bytes[5]);

	my $result = JSON->new->utf8->canonical->encode(
		{ mode => $opmode, fanmode => $fanmode, schedmode => $schmode, fanspeed => $fanspeed, heatset => $heatset, coolset => $coolset }
	);

	retain "${name}_JSON/$instance" => $result;
	retain "${name}/$instance" => sprintf("%s,%s,%s,%s,%s,%s,%s",$opmode,$fanmode,$schmode,$heatset,$coolset,$fanspeed,$pkttime);

	return "$dgn,${name}_JSON,$instance,$result";
}

sub decode_1FEF9 {
	decode_1FFE2();
}

sub decode_1FFF4 {
  state $multiple_instances_reporting = 0;
	our @bytes;
	my %binstatus=('00'=>'off','01'=>'on');

	my $rpm = hex($bytes[1].$bytes[0])/8;
	my $kph = hex($bytes[3].$bytes[2])/256;

	my @byte4_bin= binarray2($bytes[4]);
	my $parkbrake=$binstatus{$byte4_bin[0]};
	my $translock=$binstatus{$byte4_bin[1]};
	my $englock=$binstatus{$byte4_bin[2]};

	my @byte5_bin= binarray2($bytes[5]);
	my $ignition=$binstatus{$byte5_bin[0]};
	my $accessory=$binstatus{$byte5_bin[1]};
	my $gearcurr='n/a';
	$gearcurr=hex($bytes[6])-125 if(hex($bytes[6])>123);
	my $gearsel='n/a';
	$gearsel=hex($bytes[7])-125 if(hex($bytes[7])>123);

  # Some coaches (e.g. 2018) report two different sets of chassis statuses,
  # identified by F1 or F2 in Byte 0. When this is detected, be sure to only
  # use one of the statuses, to prevent a notification loop (i.e. ignition
  # is on, ignition is off, ignition is on.)
  if ($bytes[0] eq 'F1' || $bytes[0] eq 'F2') {
          $multiple_instances_reporting = 1;
  }
  retain "IGNITION" => $ignition if ($multiple_instances_reporting == 0 || $bytes[0] eq 'F1');
  retain "PARKBRAKE" => $parkbrake if ($bytes[0] eq 'F2');

	return sprintf("1FFF4,CHASSIS_MOBILITY_STATUS,%s,%s,%s,%s,%s,%s,%s,%s,%s",$rpm,$kph,$parkbrake,$translock,$englock,$ignition,$accessory,$gearcurr,$gearsel);
}

sub decode_1FFFC {
	our @bytes;
	our $pkttime;
	our $dgn;
	our %DGN_MASTER;
	my @batteries=('invalid','House','Chassis','2nd House');
	my %priorities=('20'=>'Voltmeter','40'=>'Voltmeter/Ammeter','60'=>'Inverter','80'=>'Charger','100'=>'Inverter/Charger','120'=>'Battery SOC device');

	my $priority='n/a';
	$priority=$priorities{hex($bytes[1])} if ($priorities{hex($bytes[1])});
	my $temp=tempU16($bytes[3].$bytes[2]);

	retain $DGN_MASTER{$dgn}[0]."/".hex($bytes[0]) => sprintf("%0.2f,%s",$temp,$pkttime);

	return sprintf("%s,%s,%s,%0.2f,%s",$dgn,$DGN_MASTER{$dgn}[0],$batteries[hex($bytes[0])],$temp,$priority);

}

sub decode_1FFFD {
	our @bytes;
	our $pkttime;
	our $dgn;
	our %DGN_MASTER;
	my @batteries=('invalid','House','Chassis','2nd House');
	my %priorities=('20'=>'Voltmeter','40'=>'Voltmeter/Ammeter','60'=>'Inverter','80'=>'Charger','100'=>'Inverter/Charger','120'=>'Battery SOC device');

	my $priority='n/a';
	$priority=$priorities{hex($bytes[1])} if ($priorities{hex($bytes[1])});
	my $voltage=voltageU16($bytes[3].$bytes[2]);
	my $current=currentU32($bytes[7].$bytes[6].$bytes[5].$bytes[4]);

	retain $DGN_MASTER{$dgn}[0]."/".hex($bytes[0]) => sprintf("%0.2f,%s",$voltage,$pkttime);

	return sprintf("%s,%s,%s,%0.2f,%s",$dgn,$DGN_MASTER{$dgn}[0],$batteries[hex($bytes[0])],$voltage,$current,$priority);
}

sub decode_10FFD {
  decode_1FFFD();
}


sub decode_1FFFF {
	our @bytes;
	our $pkttime;
	our $dgn;
	our %DGN_MASTER;

	my @days=('','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
	my %tzs=('0'=>'GMT','4'=>'EDT','5'=>'EST','7'=>'PDT','8'=>'PST','22'=>'Central European Time');

	my $tz='n/a';
	$tz='GMT-'.hex($bytes[7]) if ($bytes[7] ne 'FF');

	my $dt=sprintf("%4d-%02d-%02d %02d:%02d:%02d,%s,%s",hex($bytes[0])+2000,hex($bytes[1]),hex($bytes[2]),hex($bytes[4]),hex($bytes[5]),hex($bytes[6]),$tz,$days[hex($bytes[3])]);

	retain $DGN_MASTER{$dgn}[0]."/0" => $dt.",".$pkttime;
	return join(',',$dgn,$DGN_MASTER{$dgn}[0],$dt);
}
