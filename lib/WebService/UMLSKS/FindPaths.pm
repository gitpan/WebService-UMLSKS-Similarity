

=head1 NAME

GetParents- Finds all possible paths between two concepts along with shortest 
of all the paths.

=head1 SYNOPSIS
no warnings qw/redefine/;
=head2 Basic Usage

    use WebService::UMLS::find_shortest_path;
    
	my $get_paths = new FindPaths;  
	my $parentInfo_ref = \%ParentInfo;
	# %ParentInfo is hash in which key is a concept and value is an array of it's parents' CUIs.
	# $source and $destination are the two input terms.
	$get_paths->find_paths($ParentInfo_ref,$source,$destination);  
   


=head1 DESCRIPTION

This module has package FindPaths which has subroutines 'new' and find_paths.


=head1 Methods

The subroutins are as follows:


=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

#use lib "/home/mugdha/workspace/thesis_modules/lib/WebService/UMLS";
use SOAP::Lite;
use strict;
use WebService::UMLSKS::get_parents;
#use get_allowable_paths;
#use get_parents;
no warnings qw/redefine/;


# Using Graph module from CPAN for forming graph of concepts and getting 
# the shortest path between two concepts.
# Reference: http://search.cpan.org/~jhi/Graph-0.94/lib/Graph.pod

#use lib "/home/mugdha/workspace/getInfo/Graph-0.94/lib";
use Graph;
use Graph::Undirected;

package WebService::UMLSKS::FindPaths;

my @nodes;

=head2 new

This sub creates a new object of FindPaths

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}


=head2 find_paths


find_paths: This sub uses a Graph module from CPAN and creates a graph
using the concepts and their parent concepts. It finds shortest path between two
input concepts and displays the path. 

=cut

sub find_paths
{
	
	my $self = shift;
	my $ParentInfo_ref= shift;
	my $s= shift;
	my $d = shift;
	my %ParentInfo = %$ParentInfo_ref; 
	my %Concept = %$GetParents::ConceptInfo_ref;
			
	print"\n Source is : $s,Destination is: $d\n";
	my $c = 0;
	foreach my $v (keys %ParentInfo){
							$c++;
								}
	
	
    my $graph = Graph::Undirected->new; # An undirected graph.
	
	# store all the vertices in graph.		
	# assiging array as a value in hash
	# When you say $new_hash{$some_key1} = @some_array1; you are assigning to a scalar.
	# correct: @{$new_hash{$some_key1}} = @some_array1; # extra {} are for clarity
	# getting back the array from hash value
	# my @value_array = @{$new_hash{$_}};	
	  
	 foreach my $key ( keys(%ParentInfo) ) {    # once for each key of %ParentInfo
			if ( defined( $ParentInfo{$key} ) ) {
				my @p_array = @{$ParentInfo{$key}};
				foreach my $item (@p_array){
					if(defined ($key) && defined ($item)){
						$graph->add_edge($key,$item);
					}
					
				}
			}
	 } 

	 my $v = $graph->vertices;
	 my $e = $graph->edges;
	  	 
	 my @path = $graph->SP_Dijkstra($s, $d);
	 if((@path) || $#path == 0){
	 print "\npath is";
	 foreach my $n (@path){
	 	print "->$Concept{$n} ($n)";
	 }
	 }
	 else{
	 	print "\nThere is no path between input concepts.";
	 }
	 
}

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

=back


=head1 SEE ALSO

GetUserData.pm  Query.pm  ws-getShortestPath.pl GetParents.pm

=cut

=head1 AUTHORS

Mugdha Choudhari             University of Minnesota Duluth
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
