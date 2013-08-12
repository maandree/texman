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


my @italic = split(/ /, 'var code i emph kbd option command file');
my @bold = split(/ /, 'b');

my %values = ();
my @stack = ();
my $alpha = "";
my $beta = "";


foreach my $arg (@ARGV)
{
    if ($arg =~ m/=/)
    {
	my @parts = split(/=/, $arg);
	$values{$parts[0]} = join('=', @parts[1..$#parts]);
    }
}


my $buf = "";
while(1)
{
    my $line = <STDIN> || die "Missing \@bye at end of document";
    $line =~ s/\n//g;
    $line =~ s/\r//g;
    $line =~ s/\x09/ /g;
    $line =~ s/\\/\\\\/g;
    $line =~ s/^\./\\\./g;
    
    my $position = 0;
    while ($position >= 0)
    {
	if (length($buf) > 0)
	{
	    my $at = index($line, "@");
	    my $cb = index($line, "}");
	    $position = $at < 0 ? $cb : $cb < 0 ? $at : $at < $cb ? $at : $cb;
	}
	else
	{
	    $position = index($line, "@");
	}
	if ($position < 0)
	{
	    if (length($buf) == 0)
	    {
		print "${line}\n";
	    }
	    else
	    {
		$buf = "${buf}${line}\n";
	    }
	}
	elsif (substr($line, $position) =~ m/^}/)
	{
	    my $start = pop @stack;
	    $start = 0;
	    my $command = substr($buf, $start);
	    my $post = substr($line, 0, $position + 1);
	    $command = "${command}${post}";
	    $line = substr($line, $position + 1);
	    $buf = substr($buf, 0, $start);
	    my $out = "";
	    
	    if ($command =~ m/^\@set{/)
	    {
		$alpha = substr($command, 5, length($command) - 6);
		push(@stack, length($buf));
		$out = "\@set-";
	    }
	    elsif ($command =~ m/^\@set-{/)
	    {
		$beta = substr($command, 6, length($command) - 7);
		$values{$alpha} = $beta if !exists $values{$alpha};
	    }
	    elsif ($command =~ m/^\@texman{/)
	    {
		$alpha = substr($command, 8, length($command) - 9);
		push(@stack, length($buf));
		$out = "\@texman-";
	    }
	    elsif ($command =~ m/^\@texman-{/)
	    {
		$beta = substr($command, 9, length($command) - 10);
		push(@stack, length($buf));
		$out = "\@texman--";
	    }
	    elsif ($command =~ m/^\@texman--{/)
	    {
		my $gamma = substr($command, 10, length($command) - 11);
		$alpha = uc $alpha;
		$out = ".TH ${alpha} ${beta} ${gamma}";
	    }
	    elsif ($command =~ m/^\@bye /)
	    {
		exit 0
	    }
	    elsif ($command =~ m/^\@bye$/)
	    {
		exit 0
	    }
	    else
	    {
		foreach my $cmd (@italic)
		{
		    if ($command =~ m/^\@${cmd}{/)
		    {
			$out = substr($command, 2 + length($cmd));
			$out = substr($out, 0, length($out) - 1);
			$out =~ s/\x00\\fP\x01/\\fP\\fI/g;
			$out = "\\fI${out}\x00\\fP\x01";
		    }
		}
		foreach my $cmd (@bold)
		{
		    if ($command =~ m/^\@${cmd}{/)
		    {
			$out = substr($command, 2 + length($cmd));
			$out = substr($out, 0, length($out) - 1);
			$out =~ s/\x00\\fP\x01/\\fP\\fB/g;
			$out = "\\fB${out}\x00\\fP\x01";
		    }
		}
		if ($command =~ m/^\@url{/)
		{
		    $out = substr($command, 5, length($command) - 6);
		    $out =~ s/\x00\\fP\x01/\\fP\\fB/g;
		    $out = "\\fB${out}\x00\\fP\x01";
		}
		if ($command =~ m/^\@value{/)
		{
		    $out = substr($command, 7, length($command) - 8);
		    $out = $values{$out};
		}
	    }
	    
	    $buf = "${buf}${out}";
	    if ($#stack == -1)
	    {
		$buf =~ s/\x00//g;
		$buf =~ s/\x01//g;
		print $buf;
	    }
	}
	else
	{
	    if (length($buf) == 0)
	    {
		print substr($line, 0, $position);
		$line = substr($line, $position);
	    }
	    
	    my $out = "";
	    if ($line =~ m/^\@\@/)
	    {
		$out = "@";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@{/)
	    {
		$out = "{";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@}/)
	    {
		$out = "}";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@\+/)
	    {
		$out = "+";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@-/)
	    {
		$out = "-";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@\*/)
	    {
		$out = ".br";
		$line = substr($line, 2);
	    }
	    elsif (($line =~ m/^\@c/) && !($line =~ m/^\@c[a-z]+{/))
	    {
		$out = ".\\\"";
		$line = substr($line, 2);
	    }
	    elsif ($line =~ m/^\@item /)
	    {
		$out = ".TP\n.B ";
		$line = substr($line, 6);
	    }
	    elsif ($line =~ m/^\@section /)
	    {
		$out = ".SH ";
		$line = uc substr($line, 9);
	    }
	    else
	    {
		push(@stack, length($buf) + $position);
		$position = index($line, "{") + 1;
		my $pre = substr($line, 0, $position);
		$buf = "${buf}${pre}";
		$line = substr($line, $position);
	    }
	    
	    if (length($buf) == 0)
	    {
		print $out;
	    }
	    else
	    {
		$buf = "${buf}${out}";
	    }
	}
    }
}

