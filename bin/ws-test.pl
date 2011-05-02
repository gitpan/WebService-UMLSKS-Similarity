#!/usr/bin/env perl

use Getopt::Long;
use strict;


my $test_file ;
my $config_file;
my $login_file;

GetOptions( 'testfile=s' => \$test_file, 'config=s' => \$config_file, 'login=s' => \$login_file);

if($test_file eq "" || $login_file  eq "" || $config_file eq "")
{
	print "\n Please specify options --testfile, --login and --config for testing\n";
	exit;
}


if($test_file ne "" && $config_file ne "" && $login_file ne ""){
	
	open(MYDATA, $test_file) or  die("Error: cannot open file 'data.txt'\n");
	
	
	# This is creating the file for writing output
	open(OUTPUT,">","output.txt") or die("Error: cannot open file 'output.txt'\n");
	close OUTPUT;
	
	open(TIME,">","time.txt") or die("Error: cannot open file 'time.txt'\n");
	close TIME;
	
	open(OUT,">","inter_output.txt") or die("Error: cannot open file 'inter_output.txt'\n");
	close OUT;
		
	my $line;
	
	my $lnum = 1;
	while( $line = <MYDATA> ){
	  	chomp($line);
	  	#print "$lnum: $line\n";
	  	
	  	$line =~ /\s*(.*)\s*<>\s*(.*?)$/;
	  	my $query1 = $1;
	  	my $query2 = $2;
	  	$query1 =~ s/\s*//g;
	  	$query2 =~ s/\s*//g;
	
	
	 # msg ( "\nquery1 : $query1, query2: $query2", $verbose);
	  
	  
	  system("/usr/bin/perl ws-getAllowablePath.pl --input1 $query1 --input2 $query2 --login $login_file --config $config_file");
	  
	 # exit;
	  #	push(@querylist1, $query1);
	  	#push(@querylist2, $query2);
	  	#$input{$query1} = $query2;
	  
	}	
	
}





