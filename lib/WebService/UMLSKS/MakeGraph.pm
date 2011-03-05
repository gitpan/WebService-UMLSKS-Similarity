=head1 NAME

WebService::UMLSKS::MakeGraph - Form a graph by accepting parents and siblings from UMLS.


=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::MakeGraph;

=head1 DESCRIPTION

This module forms a graph.

=head1 SUBROUTINES

The subroutines are as follows:

=cut

###############################################################################
##########  CODE STARTS HERE  #################################################

# This module has package  MakeGraph

# Author  : Mugdha Choudhari

# Description : this module makes a graph stored in form of hash of hash


use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220

use WebService::UMLSKS::GetAllowablePaths;
use WebService::UMLSKS::GetParents;
use WebService::UMLSKS::Query;
use WebService::UMLSKS::ConnectUMLS;

package WebService::UMLSKS::MakeGraph;

my %node_cost;
my %Graph;

# This sub creates a new object of GetAllowablePaths



=head2 new

This sub creates a new object of MakeGraph.

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}



=head2 form_graph

This sub creates a new object of form_graph.

=cut

sub form_graph

{
	
my $self = shift;	
my $term1 = shift;	
my $term2 = shift;
my $service = shift;


# Creating GetParents object to get back the parents of input terms.

my $read_parents = WebService::UMLSKS::GetParents->new;

	
my @queue = ();

my $current_available_cost = 100000;
my $pcost                  = 10;
my $scost                  = 30;
my @parents                = ();
my @sib                    = ();
$node_cost{$term1} = 0;
$node_cost{$term2} = 0;

push( @queue, $term1 );
push( @queue, $term2 );

my $get_info  = WebService::UMLSKS::GetParents->new;
my $get_paths = WebService::UMLSKS::GetAllowablePaths->new;

my $cost_upto_current_node = 0;
my $current_node           = "";
my @visited                = ();
my @current_shortest_path = ();
my $final_cost;
#until queue is empty
while ( $#queue != -1 ) {

	@parents = ();
	@sib     = ();
#	printQueue(\@queue);

	my $current_node = shift(@queue);
	push( @visited, $current_node );
#	print "\n visited : @visited";
	my $cost_upto_current_node = $node_cost{$current_node};
#	print
#"\n current node : $current_node and cost till here : $cost_upto_current_node";
	if ( $cost_upto_current_node >= $current_available_cost ) {
		print "\n ###########################################################
		\nIgnore node as it would lead to longer path";
		next;
	}

	my $neighbors_hash_ref = call_getconceptproperties($current_node, $service);
	my $neighbors_info_ref = $read_parents-> read_object($neighbors_hash_ref);
	
	if(defined $neighbors_info_ref)
	{
		@parents = @$neighbors_info_ref;
		foreach my $p (@parents){
			$Graph{$current_node}{$p} = 1;
			$Graph{$p}{$current_node} = 2;
		}
	}
	
	#@parents = @{ $get_info->getP($current_node) };
	#@sib     = @{ $get_info->getS($current_node) };

#	print "\n parents of $current_node : @parents";
#	print "\n siblings of $current_node : @sib";
	if ( $#parents == -1 && $#sib == -1 ) {
		next;
	}
	else {
		if ( $#parents != -1 ) {
			foreach my $parent (@parents) {
#				print "\n parent is : $parent";
				unless ( $parent ~~ @visited ) {
#					print "\n parent $parent not visited";
					my $total_cost_till_parent =
					  $cost_upto_current_node + $pcost;
					if ( $parent ~~ %node_cost ) {
#						print "\n $parent is already in node cost hash";
						if ( $node_cost{$parent} > $total_cost_till_parent ) {
#							print
#							  "\n changing value of $parent in node cost hash";
							$node_cost{$parent} = $total_cost_till_parent;
						}
					}
					else {
#						print
#"\n parent $parent not in node hash, so add to hash and push in queue";
						$node_cost{$parent} = $total_cost_till_parent;
						push( @queue, $parent );

					}
				}

			}

		}

		if ( $#sib != -1 ) {
			foreach my $sib (@sib) {
				#print "\n sibling is : $sib";
				unless ( $sib ~~ @visited ) {
					#print "\n sibling $sib not visited";
					my $total_cost_till_sib = $cost_upto_current_node + $scost;
					if ( $sib ~~ %node_cost ) {
						#print "\n $sib is already in node cost hash";
						if ( $node_cost{$sib} > $total_cost_till_sib ) {
							#print "\n changing value of $sib in node cost hash";
							$node_cost{$sib} = $total_cost_till_sib;
						}
					}
					else {
						#print
#"\n sibling $sib not in node hash, so add to hash and push in queue";
						$node_cost{$sib} = $total_cost_till_sib;
						push( @queue, $sib );

					}
				}

			}

		}
	}
	
#	@queue = ();
#	foreach my $key ( sort { $node_cost{$a} <=> $node_cost{$b} } keys %node_cost ) {
#		unless($key ~~ @visited)
#		{
#			push(@queue, $key);
#		}
#	}

	if($#queue > 50)
	{
		print "\n Taking too long to find path.. so exiting!";
		exit;
	}	

	my $subgraph = \%Graph;

	@current_shortest_path = ();

	# Check if a shortest allowable path exists between source and destination
	if ( $get_paths->get_shortest_path_info( $subgraph, $term1, $term2 ) != -1 )
	{
		my @path_info =
		  @{ $get_paths->get_shortest_path_info( $subgraph, $term1, $term2 ) };
		@current_shortest_path  = @{ shift(@path_info) };
		$current_available_cost = shift(@path_info);
	}

	$final_cost = $current_available_cost;
	#print "\n current shortest path : @current_shortest_path";

	#print "\n current available path cost : $current_available_cost";

}

print "\n Final shortest path : @current_shortest_path";

print "\n final path cost : $final_cost";

#print "\n the parents are @parents";
#print "\n siblings are @sib";


	
}


#sub printQueue {
#	my $q_ref = shift;
#	my @queue = @$q_ref;
#	print "\nCurrent Queue is: \n ";
#	foreach my $ele (@queue) {
#		print "\t$ele , $node_cost{$ele}";
#	}
#}


=head2 call_getconceptproperties

This subroutines queries webservice getConceptProperties

=cut

sub call_getconceptproperties {

	my $cui = shift;
	my $service = shift;
	my $parents_ref;
	
	# Creating object of query and passing the method name along with parameters.

	my $query = WebService::UMLSKS::Query->new;
	
	
	# Creating Connect object to call sub get_pt while forming a query.

	my $c = WebService::UMLSKS::ConnectUMLS->new;
	
	
	#print "\n calling ws for cui $cui";
	$service->readable(1);
	$parents_ref = $query->runQuery(
		$service,$cui,
		'getConceptProperties',
		{
			casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
			CUI => SOAP::Data->type( string => $cui ),

			# CUI => "asfa",
			language => 'ENG',
			release  => '2009AA',
			
			#SABs => [(@sources)],
			SABs => [qw( SNOMEDCT )],
			includeConceptAttrs  => 'false',
			includeSemanticTypes => 'false',
			includeTerminology   => 'false',

			#includeDefinitions   => 'true',
			includeSuppressibles => 'false',

			includeRelations => 'true',
			relationTypes    => ['PAR'],
		},
	);
	if (!defined $parents_ref)
	{
		print "\n ref not defined";
	}
	if($parents_ref eq 'empty')
	{
		print "\n no parents for $cui";
	}
#	print "\nhash returned by ws : $parents_ref";
	return $parents_ref;
}



1;


#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

## =back spurious back removed by tdp


=head1 SEE ALSO

ValidateTerm.pm  GetUserData.pm  Query.pm  ws-getUMLSInfo.pl 

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