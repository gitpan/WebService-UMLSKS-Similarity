=head1 NAME

WebService::UMLSKS::GetAllowablePaths - Get an allowable shortest path between the input terms.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::GetAllowablePaths;

    

=head1 DESCRIPTION

Get an allowable shortest path between the input terms.

=head1 SUBROUTINES

The subroutines are as follows:

=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

# This module has package  GetAllowablePaths

# Author  : Mugdha Choudhari

# Description : this module takes a graph stored in form of hash of hash
# along with source and destination as input.


#use lib "/home/mugdha/workspace/getInfo";


#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220

use WebService::UMLSKS::GetNeighbors;

#use Proc::ProcessTable;



package WebService::UMLSKS::GetAllowablePaths;

my $pcost = 10;
my $scost = 30;
#open (LOG ,">", "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/LOG1") or die "could not open log file";

use Log::Message::Simple qw[msg error debug];
my $verbose = 0;
my $regex = "";

my $current_shortest_length = 30000;
my %Concept = ();

=head2 new

This sub creates a new object of GetAllowablePaths

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}



#sub memory_usage {
#  my $t = new Proc::ProcessTable;
#  foreach my $got ( @{$t->table} ) {
#    next if not $got->pid eq $$;
#    return $got->size;
#  }
#}


=head2 get_shortest_path_info

This sub returns the shortest path along with its cost

=cut

sub get_shortest_path_info
{
	
	my $self     = shift;
	my $hash_ref = shift;
	my $source      = shift;
	my $destination = shift;
	my $ver = shift;
	$regex = shift;
	$verbose = $ver;
	
	
	#print "memory after just coming inside get_shortest_path_info: ". memory_usage()/1024/1024 ."\n";
	
	
	
	 %Concept = %$WebService::UMLSKS::GetNeighbors::ConceptInfo_ref;
	#%Concept = %Conceptinfo;
	
	#print "memory get_shortest_path_info:after initialising hash concept ". memory_usage()/1024/1024 ."\n";
	#print "memory get_shortest_path_info: ". memory_usage()/1024/1024 ."\n";
	
	#printHoH($hash_ref);
	my $getallpaths_ref = get_allpaths($hash_ref,$source,$destination,$regex);
	#print "memory get_shortest_path_info:after get all paths ". memory_usage()/1024/1024 ."\n";
	
	if($getallpaths_ref != -1){
		my @possible_paths = @{$getallpaths_ref};
		
		#undef $getallpaths_ref;
		#print "memory get_shortest_path_info:after undef getallpath_ref ". memory_usage()/1024/1024 ."\n";
		#msg( "\npossible paths between $source and $destination : @possible_paths", $verbose);
		
		if($#possible_paths != -1 )
		{
			my @shortest_path_info = @{get_shortest_path( \@possible_paths , $hash_ref)};
		#	print "memory get_shortest_path_info:after get shortest path is called ". memory_usage()/1024/1024 ."\n";
			undef @possible_paths;
		#	print "memory get_shortest_path_info:after undef possible paths array ". memory_usage()/1024/1024 ."\n";
			undef $hash_ref;
		#	print "memory get_shortest_path_info:after undef the hash ref ". memory_usage()/1024/1024 ."\n";
			if ($#shortest_path_info != -1)
				{
					return \@shortest_path_info;
		
				}
				else
				{
					return -1;
				}
		}
		else
		{
			return -1;
		}	
	}
	elsif($getallpaths_ref == -1)
	{
		return -2;
		
	}	

	
}

# This sub implements the BFS algorithm to find all possible paths between
# source and destination in the bidirected graph


=head2 get_allpaths

This sub implements the BFS algorithm to find all possible paths between
source and destination in the bidirected graph

=cut

sub get_allpaths {

	
	my $hash_ref = shift;

	# Source and destination
	my $source      = shift;
	my $destination = shift;
	my $allowed_patterns_regex = shift;
	my %graph       = %$hash_ref;
	
	#printHoH(\%graph);


		#print "memory get_allpaths: after creating copy of graph ". memory_usage()/1024/1024 ."\n";
		#print "memory get_allpaths: ". memory_usage()/1024/1024 ."\n";
	
# FIFO queue used for Breadth First Traversal
# This queue is a list of list
# Each element is a path (list) to a node which is last element of the list
# For ex., if the first element of queue is (A,B,C), this is path to get to node C.

	my @queue = ();

	# Initial path to source
	my @t_path = ();

	# Initialize Queue by pushing source

	push( @t_path, $source );
	my $t_ref = \@t_path;
	push( @queue, $t_ref );

	# To store all possible paths between source and destination
	my @possible_paths = ();

	# List used to store the temporary paths
	my @temp_path = ();
	#print "memory get_allpaths:before while loop ". memory_usage()/1024/1024 ."\n";
	
	my $counter = 0;
	
	# While queue is not empty traverse the graph
	while ( $#queue != -1 ) {
		
		$counter++;
	#	print "memory get_allpaths:just in while loop ". memory_usage()/1024/1024 ."\n";
		my $temp_path_ref = shift(@queue);
		@temp_path = @$temp_path_ref;
		my $last_node = $temp_path[$#temp_path];
		
		if ( $last_node eq $destination ) {

			#print "memory get_allpaths:got one of the path ". memory_usage()/1024/1024 ."\n";
			# one of the paths is found so store it.

			my @possiblepath = @temp_path;
			
		
			
				#print "memory get_allpaths:before checking allowable ". memory_usage()/1024/1024 ."\n";			
			
				#print "memory get_allpaths:after checking allowable ". memory_usage()/1024/1024 ."\n";				
			
			push( @possible_paths, \@possiblepath );

		}
		
		
			#print "memory get_allpaths:before traversing neighbors ". memory_usage()/1024/1024 ."\n";			
		foreach my $link_node ( keys %{ $graph{$last_node} } ) {

			# Traverse all the neighbors of the current node in queue

			if ( $link_node ~~ @temp_path ) {
			}
			else {

				my @new_path = ();
				@new_path = @temp_path;
				push( @new_path, $link_node );
				
				
				# Check if this path is allowable
				my $path_string = "";
				for my $i ( 0 .. $#new_path - 1 ) {
					my $first_node = $new_path[$i];
					my $next_node  = $new_path[ $i + 1 ];
					my $direction  = $graph{$first_node}{$next_node};
					$path_string = "$path_string" . "$direction"; # i HATE THIS LINEEEEEEE
	
			    }
				
				if ( $path_string =~ m/$allowed_patterns_regex/ ) {
					#msg("\n path $path_string is allowed", $verbose);
					my $new_path_ref = \@new_path;
					push( @queue, $new_path_ref );

				}	
				
				
				
				
			

			}
			
		}
			#print "memory get_allpaths:after traversing neighbors ". memory_usage()/1024/1024 ."\n";			
	}

	#print "memory get_allpaths: after finding all paths ". memory_usage()/1024/1024 ."\n";
	undef %graph;
	undef $hash_ref;
	
	#print "memory get_allpaths:after undef graph and ref ". memory_usage()/1024/1024 ."\n";
	
	if($#possible_paths != -1)
	{
	msg("\n************************************************************", $verbose);
	#msg("\n All possible paths between $source and $destination are:", $verbose);
	
	my $stop_flag = 0;
	
	
	# If all possible paths exceed above threshold then stop searching
	foreach my $i ( 0 .. $#possible_paths ) {
		my @path = @{ $possible_paths[$i] };
		if($#path <= $current_shortest_length || $#path <= 20){
			$stop_flag = 1; 
		}
		
		
	}
	if($stop_flag == 0)
	{
		msg("\n********* STOP ***********\n", $verbose);
		return -1;
	}
	
	
	#foreach my $i ( 0 .. $#possible_paths ) {
	#	my @path = @{ $possible_paths[$i] };
		
		#msg("\npath $i is : @path", $verbose);
	#}
	#print "memory get_allpaths:only possible path remaining ". memory_usage()/1024/1024 ."\n";
	return \@possible_paths;
	#get_allowable_paths( \@possible_paths, \%graph );
	}
	else
	{
		msg("\n no path exists between $source and $destination till now", $verbose);
		return \@possible_paths;
	}
}


=head2 get_shortest_path

This sub finds the shortest path between the two terms.

=cut

sub get_shortest_path {
	my $allowed_paths_ref = shift;
	my @allowed_paths     = @$allowed_paths_ref;
	my $graph_ref     = shift;
	my %graph         = %$graph_ref;
	
	msg("\n************************************************************", $verbose);
	msg("\n Finding shortest of all allowed paths:", $verbose);
	
	my @path_string = ();
	my $length = 100000;
	my $path_cost = 100000;
	my $shortest_path_ref;
	my $change_in_direction = -1;
	my @shortest_path_direction;
	
	foreach my $path (@allowed_paths) {
		my @candidate_path = @$path;
		#msg("\n allowed candidate path  : @candidate_path", $verbose);

		# Right now the shortest path is the one that has minimum nodes.
#		my $current_path_len = $#candidate_path;
#		if ( $current_path_len < $length ) {
#			$length            = $current_path_len;
#			$shortest_path_ref = \@candidate_path;
#		}

		my $current_path_cost = 0;	
		my $current_direction = 0;
	    $change_in_direction = -1;
		 @path_string = ();
		my $arrow_direction = "";
				
		for my $i ( 0 .. $#candidate_path - 1 ) {
			my $first_node = $candidate_path[$i];
			my $next_node  = $candidate_path[ $i + 1 ];
			my $direction  = $graph{$first_node}{$next_node};
			if($direction == 1)
			{
				
				$arrow_direction = "U"; 
				
			}
			if($direction == 2)
			{
				
				$arrow_direction = "D"; 
				
			}
			if($direction == 3)
			{
				
				$arrow_direction = "H"; 
				
			}
			push(@path_string, $arrow_direction);
			
			# If a parent or child relation then add the parent cost
			if($direction =~ /\b1\b|\b2\b/)
			{
				$current_path_cost = $current_path_cost + $pcost;
			}
			# If a sibling relation then add the sibling cost
			elsif($direction =~ /\b3\b/)
			{
				$current_path_cost = $current_path_cost + $scost;
			}
			
			# If current direction is not equal to previous direction, then 
			# increament the number of chnages in direction in current path.
			if($current_direction != $direction)
			{
				$change_in_direction++;
				$current_direction = $direction;
				
			}

		}
		#msg("\n cost of candidte path : @candidate_path : is : $current_path_cost", $verbose);
		#msg("\n path cost is : $path_cost", $verbose);
		if($current_path_cost < $path_cost)
		{
			$path_cost = $current_path_cost;
			$shortest_path_ref = \@candidate_path;
			@shortest_path_direction = @path_string;
		}


	}
	my @shortest_path_info = ();
	undef %graph;
	undef $graph_ref;
	undef @allowed_paths;
	undef $allowed_paths_ref;
	
	if(defined $shortest_path_ref)
	{
		$current_shortest_length = $path_cost / 10;
		msg("\n shortest path : @$shortest_path_ref", $verbose);
		msg("\n shortest cost : $path_cost", $verbose);
		msg("\n changes in direction for current shortest path : $change_in_direction", $verbose );
		msg("\n shortest path direction path string : @shortest_path_direction", $verbose);
		push(@shortest_path_info,$shortest_path_ref);
		push(@shortest_path_info,$path_cost);
		push(@shortest_path_info, $change_in_direction);
		push(@shortest_path_info, \@shortest_path_direction);
		
		return \@shortest_path_info;
	}
	else
	{
		return \@shortest_path_info;
	}
	
	

}


=head2 printHoH

This subroutines prints the current contents of hash of hash

=cut

sub printHoH {

	my $hoh = shift;
	my %hoh = %$hoh;

	msg( "\nin printHoH : Graph is :", $verbose);
	foreach my $ngram ( keys %hoh ) {
		msg("\n***************************************************", $verbose);
		msg( "\n" . $ngram . "{", $verbose);
		foreach my $word ( keys %{ $hoh{$ngram} } ) {
			msg( "\n", $verbose);
			msg( $word. "=>" . $hoh{$ngram}{$word}, $verbose);
		}
		msg( "\n}", $verbose);

	}

}


=head2 printHash

This sub prints argument hash.

=cut

sub printHash
{
	my $ref = shift;
	my %hash = %$ref;
	foreach my $key(keys %hash)
	{
		print "\n $key => $hash{$key}";
	}
}

#printHoH(\%ParentInfo);



=head1 SEE ALSO

GetUserData.pm  Query.pm  ws-getShortestPath.pl GetParents.pm

=cut

=head1 AUTHORS

Mugdha Choudhari,             University of Minnesota Duluth
                             E<lt>chou0130 at d.umn.eduE<gt>

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>




=head1 COPYRIGHT

Copyright (C) 2010, Mugdha Choudhari, Ted Pedersen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to 
The Free Software Foundation, Inc., 
59 Temple Place - Suite 330, 
Boston, MA  02111-1307, USA.

=cut

#---------------------------------PERLDOC ENDS HERE---------------------------------------------------------------



1;
