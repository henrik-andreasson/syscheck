#!/usr/bin/perl

#    multiple_readers.pl: test the pcsc Perl wrapper with TWO readers
#    Copyright (C) 2001  Lionel Victor, 2003 Ludovic Rousseau
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: list_reader.pl,v 1.1 2006-10-30 17:14:44 kinneh Exp $

use ExtUtils::testlib;
use Chipcard::PCSC;

use warnings;
use strict;

my $hContext;
my @ReadersList;

if( defined $ARGV[0] && "x$ARGV[0]" eq "x--help" ){
	print "### When all is ok: $0 returns: ###\n";
	print "Retrieving readers'list:\n";
	print "  OMNIKEY CardMan 3x21 01 00\n";
	print "  Number of attatched readers: 1\n";
	print "### When No readers connected ###\n";
	print "  Retrieving readers'list:\n";
	print "  Can't get readers' list: Command successful.\n";
	print "### When we get no contact with pcscd ###\n";
	print "  Can't create the pcsc object: Service not available.\n";
	exit;

}

#-------------------------------------------------------------------------------
$hContext = new Chipcard::PCSC();
die ("Can't create the pcsc object: $Chipcard::PCSC::errno\n") unless (defined $hContext);

#-------------------------------------------------------------------------------
print "Retrieving readers'list:\n";
@ReadersList = $hContext->ListReaders ();
die ("Can't get readers' list: $Chipcard::PCSC::errno\n") unless (defined($ReadersList[0]));
$, = "\n  ";
$" = "\n  ";
print "  @ReadersList\n";

my $number = $#ReadersList;
$number++;
print "Number of attatched readers: $number\n";

# End of File #

