#!/usr/bin/perl

my $str  = shift @ARGV;
my $arg1 = shift @ARGV;
my $arg2 = shift @ARGV;
my $arg3 = shift @ARGV;
my $arg4 = shift @ARGV;
my $arg5 = shift @ARGV;
my $arg6 = shift @ARGV;
my $arg7 = shift @ARGV;
my $arg8 = shift @ARGV;
my $arg9 = shift @ARGV;

open (PF, ">>/tmp/pf.tmp");
print PF "str: $str args: $arg1 $arg2,$arg3,$arg4,$arg5,$arg6,$arg7,$arg8,$arg9,\n";
my $outp = sprintf("$str", $arg1, $arg2,$arg3,$arg4,$arg5,$arg6,$arg7,$arg8,$arg9);
print PF $outp . "\n";
print $outp;
close PF;
