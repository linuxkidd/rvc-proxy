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

our $debug = 0;

our %loads = (
  1 => "Bedroom",
);

our %deccommands = (
  0 => 'Off', 1 => 'Low', 2 => 'High',
);

if ( scalar(@ARGV) < 2 ) {
  print "ERR: Insufficient command line data provided.\n";
  usage();
}

if (!exists($loads{$ARGV[0]})) {
  print "ERR: Load does not exist.  Please see load list below.\n";
  usage();
}

if (!exists($deccommands{$ARGV[1]})) {
  print "ERR: Command not allowed.  Please see command list below.\n";
  usage();
}


our ($prio,$dgnhi,$dgnlo,$srcAD,$instance,$command) = (6,'1FE','DB',96,$ARGV[0],$ARGV[1]);
our ($hexData,$binCanId,$hexCanId) = (0,0,0);

our %specials = (
  1 => { 0 => [ 35, 36 ], 1=> [ 35, 36 ], 2 => [ 36, 35 ] },
);

if (exists($specials{$instance})) {
  $binCanId = sprintf("%b0%b%b%b",hex($prio),hex($dgnhi),hex($dgnlo),hex($srcAD));
  $hexCanId = sprintf("%08X",oct("0b$binCanId"));

  if ($command > 0) {
    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],5,255);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  } else {
    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[0],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);

    $hexData = sprintf("%02XFFC8%02X%02X00FFFF",$specials{$instance}{$command}[1],3,0);
    system('cansend can0 '.$hexCanId."#".$hexData) if (!$debug);
    print 'cansend can0 '.$hexCanId."#".$hexData . "\n" if($debug);
  }
}

sub usage {
  print "Usage: \n";
  print "\t$0 <fan-id> <command>\n";
  print "\n\t<fan-id> is one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %loads ) {
    print "\t\t".$key." = ".$loads{$key} . "\n";
  }
  print "\n\t<command> is one of:\n";
  foreach my $key ( sort {$a <=> $b} keys %deccommands ) {
    print "\t\t".$key." = ".$deccommands{$key} . "\n";
  }
  print "\n";
  exit(1);
}
