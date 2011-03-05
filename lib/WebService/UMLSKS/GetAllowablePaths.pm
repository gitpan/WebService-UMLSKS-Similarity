=head1 NAME

WebService::UMLSKS::GetAllowablePaths - Get an allowable shortest path between the input terms.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::ConnectUMLS;

    

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
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220

package WebService::UMLSKS::GetAllowablePaths;

my $pcost = 10;
my $scost = 30;


=head2 new

This sub creates a new object of GetAllowablePaths

=cut


sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}


=head2 get_shortest_path_info

This sub returns the shortest path along with its cost

=cut

sub get_shortest_path_info
{
	my $self     = shift;
	my $hash_ref = shift;
	my $source      = shift;
	my $destination = shift;
	
	my @possible_paths = @{get_allpaths($hash_ref,$source,$destination)};
	
	if($#possible_paths != -1)
	{
		my @allowable_paths = @{get_allowable_paths( \@possible_paths, $hash_ref)};
		if($#allowable_paths != -1)
		{
			my @shortest_path_info = @{get_shortest_path( \@allowable_paths , $hash_ref)};
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
	else
	{
		return -1;
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
	my %graph       = %$hash_ref;

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

	# While queue is not empty traverse the graph
	while ( $#queue != -1 ) {
		my $temp_path_ref = shift(@queue);
		@temp_path = @$temp_path_ref;
		my $last_node = $temp_path[$#temp_path];

		if ( $last_node eq $destination ) {

			# one of the paths is found so store it.

			my @possiblepath = @temp_path;
			push( @possible_paths, \@possiblepath );

		}
		foreach my $link_node ( keys %{ $graph{$last_node} } ) {

			# Traverse all the neighbors of the current node in queue

			if ( $link_node ~~ @temp_path ) {
			}
			else {

				my @new_path = ();
				@new_path = @temp_path;
				push( @new_path, $link_node );
				my $new_path_ref = \@new_path;
				push( @queue, $new_path_ref );

			}
		}
	}

	if($#possible_paths != -1)
	{
#	print "\n************************************************************";
#	print "\n All possible paths between $source and $destination are:";
	foreach my $i ( 0 .. $#possible_paths ) {
		my @path = @{ $possible_paths[$i] };
#		print "\npath $i is : @path";
	}

	return \@possible_paths;
	#get_allowable_paths( \@possible_paths, \%graph );
	}
	else
	{
	#	print "\n no path exists between source and destination till now";
		return \@possible_paths;
	}
}


=head2 get_allowable_paths

This sub filters set of allowable paths from all possible path.

=cut

sub get_allowable_paths {
	my $all_paths_ref = shift;
	my $graph_ref     = shift;
	my @all_paths     = @$all_paths_ref;
	my %graph         = %$graph_ref;

	my @allowable_paths = ();

   # This regex is formed using the allowed paths' patterns given in HSO paper
   # Here 1, denotes upward arrow/vector, 2 denotes downward arrow and 3 denoted
   # horizontal arrows.

	# Currently any length of vector is allowed.

	my $allowed_patterns_regex =
	  '\b1+\b|\b1+2+\b|\b1+3+\b|\b1+3+2+\b|\b2+\b|\b2+3+\b|\b3+2+\b|\b3+\b';

	# For all possible paths, for every path, form the path string using the
	# directions of the paths that join source and destination
	
#	print "\n ***********************************************************";
#	print "\n Finding allowed paths";


	foreach my $path (@all_paths) {
		my @candidate_path = @$path;
#		print "\n possible candidate path : @candidate_path";
		my $path_string = "";
		for my $i ( 0 .. $#candidate_path - 1 ) {
			my $first_node = $candidate_path[$i];
			my $next_node  = $candidate_path[ $i + 1 ];
			my $direction  = $graph{$first_node}{$next_node};
#			$path_string = "$path_string" . "$direction";

		}
#		print "\n path_string formed : $path_string";

		# Now compare the path string formed for current path with the allowed
		# patterns, to find out if this path is allowed or not.
		# If allowed store it in the array of allowed paths.

		if ( $path_string =~ /$allowed_patterns_regex/ ) {
#			print "\n path $path_string is allowed";
			my $allowed_path_ref = \@candidate_path;
			push( @allowable_paths, $allowed_path_ref );

		}
		else {
#			print "\n path $path_string not allowed";
		}

	}

	if($#allowable_paths != -1)
	{
		return \@allowable_paths;
		#get_shortest_path( \@allowable_paths , \%graph);
	}
	else
	{
	#	print "\n No allowed path found between given nodes";
		return \@allowable_paths;
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
	
#	print "\n************************************************************";
#	print "\n Finding shortest of all allowed paths:";
	my $length = 100000;
	my $path_cost = 100000;
	my $shortest_path_ref;
	foreach my $path (@allowed_paths) {
		my @candidate_path = @$path;
#		print "\n allowed candidate path  : @candidate_path";
=c
		# Right now the shortest path is the one that has minimum nodes.
		my $current_path_len = $#candidate_path;
		if ( $current_path_len < $length ) {
			$length            = $current_path_len;
			$shortest_path_ref = \@candidate_path;
		}
=cut
		my $current_path_cost = 0;	

		for my $i ( 0 .. $#candidate_path - 1 ) {
			my $first_node = $candidate_path[$i];
			my $next_node  = $candidate_path[ $i + 1 ];
			my $direction  = $graph{$first_node}{$next_node};
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

		}
#		print "\n cost of candidte path : @candidate_path : is : $current_path_cost";
#		print "\n path cost is : $path_cost";
		if($current_path_cost < $path_cost)
		{
			$path_cost = $current_path_cost;
			$shortest_path_ref = \@candidate_path;
		}

	}
my @shortest_path_info = ();
	if(defined $shortest_path_ref)
	{
#		print "\n shortest path : @$shortest_path_ref";
#		print "\n shortest cost : $path_cost";
		
	push(@shortest_path_info,$shortest_path_ref);
	push(@shortest_path_info,$path_cost);
	
	return \@shortest_path_info;
	}
	else
	{
		return \@shortest_path_info;
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
