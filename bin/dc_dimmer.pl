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

use strict;
no strict 'refs';

our $debug=0;

our %deccommands=(0=>'Set Level(delay)',1=>'On (Duration)',2=>'On (Delay)',3=>'Off (Delay)',
	5=>'Toggle',6=>'Memory Off',17=>'Ramp Brightness',18=>'Ramp Toggle',19=>'Ramp Up',
	20=>'Ramp Down',21=>'Ramp Down/Up');

if ( scalar(@ARGV) < 2 ) {
	print "ERR: Insufficient command line data provided.\n";
	usage();
}

if(!exists($deccommands{$ARGV[1]})) {
	print "ERR: Command not allowed.  Please see command list below.\n";
	usage();
}

our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command,$brightness,$duration,$bypass)=(6,'1FE','DB',99,$ARGV[0],$ARGV[1],($ARGV[2]||100)*2,$ARGV[3]||255,$ARGV[4]||0);
our $binCanId=sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));

our $hexData=sprintf("%02XFF%02X%02X%02X00FFFF",$instance,$brightness,$command,$duration);
our $hexCanId=sprintf("%08X",oct("0b$binCanId"));

system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
print 'cansend can0 '.$hexCanId."#".$hexData."\n" if ($debug);
if($command==0 || $command==17) {
	sleep 5 if($command==17 && $bypass==0);
	$brightness=0;
	$command=21;
	$duration=0;
	$hexData=sprintf("%02XFF%02X%02X%02X00FFFF",$instance,$brightness,$command,$duration);
	system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if ($debug);
	$command=4;
	$hexData=sprintf("%02XFF%02X%02X%02X00FFFF",$instance,$brightness,$command,$duration);
	system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
	print 'cansend can0 '.$hexCanId."#".$hexData."\n" if ($debug);
}


sub usage {
	print "Usage: \n";
	print "\tdimmer_RV-C.pl <load-id> <command> {brightness} {time}\n";
	print "\n\t<load-id> is required and one of:\n";
	print "\t\t {1..99} (check the *.dc_loads.txt files for a list)\n";
	print "\n\t<command> is required and one of:\n";
	foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
		print "\t\t".$key." = ".$deccommands{$key} . "\n";
	}
	print "\n";
	print "\t{brightness}	- 0 to 100 (percentage)	- Optional\n";
	print "\t{time}		- 0 to 240 (seconds)	- Optional\n";
	print "\n";
	exit(1);
}
