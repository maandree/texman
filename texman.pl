#!/usr/bin/perl
use strict;
use warnings;


my @italic = split(/ /, 'var code i emph kbd option command');
my @bold = split(/ /, 'b');

my %values = ();


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
	    $values{"$var"} = "$val";
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

