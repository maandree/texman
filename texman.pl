#!/usr/bin/perl

# texman – Texinfo-like syntax for manpages
# 
# Copyright © 2013  Mattias Andrée (maandree@member.fsf.org)
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;


my @italic = split(/ /, 'var code i emph kbd option command');
my @bold = split(/ /, 'b');

my %values = ();


foreach my $arg (@ARGV)
{
    if ($arg =~ m/=/)
    {
	my @parts = split(/=/, $arg);
	$values{$parts[0]} = join('=', @parts[1..$#parts]);
    }
}


while(1)
{
    my $line = <STDIN> || die "Missing \@bye at end of document";
    die "Binary content found" if $line =~ m/\x00/;
    die "Binary content found" if $line =~ m/\x01/;
    
    $line =~ s/\x09/ /g;
    $line =~ s/\@\@/\x00\x00/g;
    $line =~ s/\@{/\x00{/g;
    $line =~ s/\@}/\x00}/g;
    $line =~ s/\@\+/\x00\+/g;
    $line =~ s/\@-/\x00-/g;
    
    $line =~ s/\\\\/\\/g;
    
    exit 0 if $line =~ m/\@bye$/;
    exit 0 if $line =~ m/\@bye /;
    
    $line =~ s/\@/\@\x01/g;
    
    my @parts = split(/\@/, $line);
    $line = "";
    foreach my $part (@parts)
    {
	$part =~ s/^\./\\\./g;
	if ($part =~ m/\x01texman{.*}{.*}{.*}/)
	{
	    $part =~ s/\x01texman{(.*)}{(.*)}{(.*)}/.TH $1 $2 "$3"/;
	    my @p = split(/ /, $part);
	    $p[1] = uc $p[1];
	    $part = join(' ', @p);
	}
	elsif ($part =~ m/\x01set{.*}{.*}/)
	{
	    my $var = "$part";
	    my $val = "$part";
	    $var =~ s/\x01set{(.*)}{(.*)}/$1/;
	    $val =~ s/\x01set{(.*)}{(.*)}/$2/;
	    $var =~ s/\n//;
	    $val =~ s/\n//;
	    $part =~ s/\x01set{(.*)}{(.*)}//;
	    $values{"$var"} = "$val" if !exists $values{"$var"};
	}
	elsif ($part =~ m/\x01.+{.*}/)
	{
	    foreach my $cmd (@italic)
	    {
		$part =~ s/\x01${cmd}{(.*)}/\\fI$1\\fP/;
	    }
	    foreach my $cmd (@bold)
	    {
		$part =~ s/\x01${cmd}{(.*)}/\\fB$1\\fP/;
	    }
	    $part =~ s/\x01url{(.*)}/\<\\fB$1\\fP\>/;
	    $part =~ s/\x01value{(.*)}/$values{$1}/;
	    die "Unrecognised command" if $part =~ m/\x01/;
	}
	elsif ($part =~ m/\x01section /)
	{
	    $part =~ s/\x01section/\.SH/;
	    $part = uc $part;
	}
	elsif ($part =~ m/\x01item /)
	{
	    $part =~ s/\x01item /\.TP\n\.B /;
	}
	elsif ($part =~ m/\x01\*/)
	{
	    $part =~ s/\x01\*/\.br/;
	}
	elsif ($part =~ m/\x01c/)
	{
	    $part =~ s/\x01c/\.\\"/;
	}
	$line = "${line}${part}";
    }
    
    $line =~ s/\x00\x00/\@/g;
    $line =~ s/\x00\+/\@\+/g;
    $line =~ s/\x00-/\@-/g;
    
    print "$line";
}

