
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

#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";
use warnings;
use SOAP::Lite;
use strict;
no warnings qw/redefine/;    #http://www.perlmonks.org/?node_id=582220

use WebService::UMLSKS::GetAllowablePaths;
use WebService::UMLSKS::GetNeighbors;
#use WebService::UMLSKS::GetParents;
use WebService::UMLSKS::Query;
use WebService::UMLSKS::ConnectUMLS;
use WebService::UMLSKS::Similarity;

package WebService::UMLSKS::MakeGraph;


use Log::Message::Simple qw[msg error debug];

my %node_cost = ();
my %Graph     = ();

my $const_C = 20;
my $const_k = 1 / 4;

my %MetaCUIs = (
	'C0332280' => 'Linkage concept',
	'C1274012' => 'Ambiguous concept',
	'C1274014' => 'Outdated concept',
	'C1276325' => 'Reason not stated concept',
	'C1274013' => 'Duplicate concept',
	'C1264758' => 'Inactive concept',
	'C1274015' => 'Erroneous concept',
	'C1274021' => 'Moved elsewhere',
	'C2733115' => 'Limited status concept',
	'C1299995' => 'Namespace concept',
	'C1285556' => 'Navigational concept',
	'C1298232' => 'Special concept',
);

my @sources   = ();
my @relations = ();
my @directions = ();

my $source;
my $destination;
my $tflag;
my $verbose = 0;

#open (LOG ,">", "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/log") or die "could not open log file";

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

	my $self    = shift;
	my $term1   = shift;
	my $term2   = shift;
	my $service = shift;
	my $ver     = shift;
	my $s_ref   = shift;
	my $r_ref   = shift;
	my $d_ref   = shift;
	my $regex   = shift;
	my $test_flag = shift;



	# Set the source and destination for use in other functions
	
	$source = $term1;
	$destination = $term2;
	$tflag = $test_flag;
	
	
	# If this is a testing mode, then create an output file
	if($test_flag == 1)
		{
		open(OUTPUT,">>","output.txt") or die("Error: cannot open file 'output.txt'\n");
		
		}	
		
	$verbose = $ver;
	
	# Set up the directions hash using the directions and relations arrays
	my %Directions = ();
	#$Directions_ref = \%Directions;
	
	
	msg( "\n in form graph : regex: $regex", $verbose );

	@sources   = @$s_ref;
	@relations = @$r_ref;
	@directions = @$d_ref;
	
	for (my $i = 0 ; $i <= $#relations ; $i++){
		$Directions{$relations[$i]} = $directions[$i];
	}

	msg("\n in makegraph",$verbose);
	#printHash(\%Directions);
	
	msg( "\n Sources used are : @sources", $verbose );

	msg( "\n Relations used are : @relations", $verbose );
	msg( "\n Directions used are : @directions", $verbose );

	%node_cost = ();
	%Graph     = ();

	msg( "\nin makegraph Term1 : $term1 , Term2: $term2", $verbose );

	# Creating GetParents object to get back the parents of input terms.

	#my $read_parents = WebService::UMLSKS::GetParents->new;

	my @queue = ();

	my $current_available_cost = 100000;
	my $pcost                  = 10;
	my $ccost                  = 10;
	my $scost                  = 30;
	my @parents                = ();
	my @sib                    = ();
	my @children               = ();
	$node_cost{$term1} = 0;
	$node_cost{$term2} = 0;

	push( @queue, $term1 );
	push( @queue, $term2 );

	#my $get_info  = WebService::UMLSKS::GetParents->new;
	my $read_parents = WebService::UMLSKS::GetNeighbors->new;
	my $get_paths    = WebService::UMLSKS::GetAllowablePaths->new;

	my $cost_upto_current_node = 0;
	my $current_node           = "";
	my @visited                = ();
	my @current_shortest_path  = ();
	my $final_cost;
	my $counter             = 0;
	my $change_in_direction = 0;
	my @path_direction = ();

	#until queue is empty
	while ( $#queue != -1 ) {

		@parents = ();
		@sib     = ();
		@children = ();
		printQueue( \@queue );

		#printHoH(\%Graph);

		my $current_node = shift(@queue);
		$counter++;
		push( @visited, $current_node );
		msg( "\n visited : @visited", $verbose );
		my $cost_upto_current_node = $node_cost{$current_node};
		msg(
		"\n current node : $current_node and cost till here : $cost_upto_current_node",
			$verbose
		);
		if ( $cost_upto_current_node >= $current_available_cost ) {
			msg( "\n ########\nIgnore node as it would lead to longer path",
				$verbose );
			next;
		}

		my $neighbors_hash_ref =
		  call_getconceptproperties( $current_node, $service );
		  if ( $neighbors_hash_ref eq 'undefined' |
			$neighbors_hash_ref eq 'empty' )
		{
			msg("\n no neighbors for $current_node",$verbose);
			next;
		}
		my $neighbors_info_ref =
		  $read_parents->read_object( $neighbors_hash_ref, $current_node, $verbose,\%Directions );

		if (  $neighbors_info_ref eq 'empty' )
		{
			msg("\n no neighbors for $current_node",$verbose);
			next;
		}

		if ( defined $neighbors_info_ref && @$neighbors_info_ref ) {
			if ( $counter == 2 ) {
				if ( $term1 eq $term2 ) {
					
					print OUTPUT "20<>$term1<>$term2\n";
					print
"\n Both the input terms share extra strong relation as they are same";
					msg(
"\n Both the input terms share extra strong relation as they are same",
						$verbose
					);
					return 'same';
				}
			}

		   # For the graph using the parents, children and siblings of the term.
			my @n = @$neighbors_info_ref;

			my $p_ref = shift(@n);
			my $c_ref = shift(@n);
			my $s_ref = shift(@n);

			if ( $p_ref ne 'empty' ) {
				@parents = @{$p_ref};
			}

			if ( $c_ref ne 'empty' ) {
				@children = @{$c_ref};
			}

			if ( $s_ref ne 'empty' ) {
				@sib = @{$s_ref};
			}

			msg( "\nparents array : @parents", $verbose );
			msg( "\nchild array : @children",  $verbose );
			msg( "\nsibling array : @sib",     $verbose );

			#@parents = @$neighbors_info_ref;
			foreach my $p (@parents) {
				unless ( $p ~~ %MetaCUIs ) {
					$Graph{$current_node}{$p} = 1;
					$Graph{$p}{$current_node} = 2;
				}
			}
			foreach my $c (@children) {
				unless ( $c ~~ %MetaCUIs ) {
					$Graph{$current_node}{$c} = 2;
					$Graph{$c}{$current_node} = 1;
				}
			}
			foreach my $s (@sib) {
				unless ( $s ~~ %MetaCUIs ) {
					$Graph{$current_node}{$s} = 3;
					$Graph{$s}{$current_node} = 3;
				}
			}
		}

		msg( "\n parents of $current_node : @parents",  $verbose );
		msg( "\n siblings of $current_node : @sib",     $verbose );
		msg( "\n children of $current_node: @children", $verbose );
		if ( $#parents == -1 && $#sib == -1 && $#children == -1 ) {
			msg("\n no neighbors at all",$verbose);
			next;
		}
		else {
			if ( $#parents != -1 ) {
				foreach my $parent (@parents) {
					msg( "\n parent is : $parent", $verbose );
					unless ( $parent ~~ %MetaCUIs ) {
						unless ( $parent ~~ @visited ) {
							msg("\n parent $parent not visited");
							my $total_cost_till_parent =
							  $cost_upto_current_node + $pcost;
							if ( $parent ~~ %node_cost ) {
								msg("\n $parent is already in node cost hash");
								if ( $node_cost{$parent} >
									$total_cost_till_parent )
								{
									msg(
"\n changing value of $parent in node cost hash",
										$verbose
									);
									$node_cost{$parent} =
									  $total_cost_till_parent;
								}
							}
							else {
								msg(
"\n parent $parent not in node hash, so add to hash and push in queue",
									$verbose
								);
								$node_cost{$parent} = $total_cost_till_parent;
								push( @queue, $parent );

							}
						}
					}

				}

			}

			if ( $#sib != -1 ) {
				foreach my $sib (@sib) {

					#print "\n sibling is : $sib";
					unless ( $sib ~~ %MetaCUIs ) {
						unless ( $sib ~~ @visited ) {

							#print "\n sibling $sib not visited";
							my $total_cost_till_sib =
							  $cost_upto_current_node + $scost;
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

			if ( $#children != -1 ) {
				foreach my $child (@children) {
					msg( "\n child is : $child", $verbose );
					unless ( $child ~~ %MetaCUIs ) {
						unless ( $child ~~ @visited ) {
							msg("\n child $child not visited");
							my $total_cost_till_child =
							  $cost_upto_current_node + $ccost;
							if ( $child ~~ %node_cost ) {
								msg("\n $child is already in node cost hash");
								if ( $node_cost{$child} >
									$total_cost_till_child )
								{
									msg(
"\n changing value of $child in node cost hash",
										$verbose
									);
									$node_cost{$child} = $total_cost_till_child;
								}
							}
							else {
								msg(
"\n child $child not in node hash, so add to hash and push in queue",
									$verbose
								);
								$node_cost{$child} = $total_cost_till_child;
								push( @queue, $child );

							}
						}
					}

				}

			}

		}

		@queue = ();
		foreach
		  my $key ( sort { $node_cost{$a} <=> $node_cost{$b} } keys %node_cost )
		{
			unless ( $key ~~ @visited ) {
				push( @queue, $key );
			}
		}

		#	if($#queue > 50)
		#	{
		#		print "\n Taking too long to find path.. so exiting!";
		#		exit;
		#	}

		my %subgraph = %Graph;

		#getinfo -> getGraph();

		@current_shortest_path = ();
		@path_direction = ();

	  # Check if a shortest allowable path exists between source and destination
		my $get_path_info_result =
		  $get_paths->get_shortest_path_info( \%subgraph, $term1, $term2,
			$verbose, $regex );
		if ( $get_path_info_result != -1 && $get_path_info_result != -2 ) {
			my @path_info = @$get_path_info_result;
			@current_shortest_path  = @{ shift(@path_info) };
			$current_available_cost = shift(@path_info);
			$change_in_direction    = shift(@path_info);
			@path_direction = @{ shift(@path_info)};
		}
		if($get_path_info_result == -2)
		{
			# Stop seraching for shortest path as the path length has already increased
			# the threshold value.
			print OUTPUT "0<>$term1<>$term2\n";
			print "\n Stopped searching as the path length exceeds the threshold value";
			
			last;
			
			
		}

		$final_cost = $current_available_cost;
		msg( "\n current shortest path : @current_shortest_path", $verbose );

		msg( "\n current available path cost : $current_available_cost",
			$verbose );
		msg( "\n current available path direction : @path_direction",
			$verbose );	

	}

	
	if (@current_shortest_path) {
		
		my %Concept = %$WebService::UMLSKS::GetNeighbors::ConceptInfo_ref;

		my $initial_relatedness =  $const_C - ($final_cost/10);
		my $semantic_relatedness = $initial_relatedness -
						(($const_k * $initial_relatedness) * $change_in_direction);

		print "\n Final shortest path :";
		
		for my $n (0 .. $#current_shortest_path) {
			if($n < $#current_shortest_path){
				print "$Concept{$current_shortest_path[$n]} ($current_shortest_path[$n]) ($path_direction[$n])->";
			}
			else
			{
				print "$Concept{$current_shortest_path[$n]} ($current_shortest_path[$n])";
			}
			
			
		}

		msg( "\n Final shortest path : ", $verbose );
		foreach my $n (@current_shortest_path) {
			msg( "->$Concept{$n} ($n)", $verbose );
		}

		print "\n Final path cost : $final_cost";
		msg( "\n Final path cost : $final_cost", $verbose );

		print "\n Semantic relatedness : $semantic_relatedness";
		msg( "\n Semantic relatednes : $semantic_relatedness", $verbose );
		if($test_flag == 1)
		{
			print OUTPUT "$semantic_relatedness<>$term1<>$term2\n";
		}
		
		

	}
	else

	{
		if($test_flag == 1)
		{
			print OUTPUT "-1<>$term1<>$term2\n";
		}
		print "\n No shortest allowable path found between the input terms/CUIs\n";
	}

	#print "\n the parents are @parents";
	#print "\n siblings are @sib";
if($test_flag == 1){
	close OUTPUT;
}

	
}

=head2 printQueue

This subroutines prints the current contents of queue

=cut

	sub printQueue {
		my $q_ref = shift;
		my @queue = @$q_ref;
		msg( ("\nCurrent Queue is: \n "), $verbose );
		foreach my $ele (@queue) {
			msg( "\t$ele, $node_cost{$ele}", $verbose );
		}
	}

=head2 call_getconceptproperties

This subroutines queries webservice getConceptProperties

=cut

	sub call_getconceptproperties {

		my $cui     = shift;
		my $service = shift;
		my $parents_ref;

   # Creating object of query and passing the method name along with parameters.

		my $query = WebService::UMLSKS::Query->new;

		# Creating Connect object to call sub get_pt while forming a query.

		my $c = WebService::UMLSKS::ConnectUMLS->new;

		#print "\n calling ws for cui $cui";
		$service->readable(1);
		my $return_ref;
		
		$return_ref = $query->runQuery(
			$service, $cui,
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

				SABs => [ (@sources) ],

				#SABs => [qw( SNOMEDCT )],
				includeConceptAttrs  => 'false',
				includeSemanticTypes => 'false',
				includeTerminology   => 'false',

				#includeDefinitions   => 'true',
				includeSuppressibles => 'false',

				includeRelations => 'true',
				relationTypes    => [(@relations)],
				#relationTypes    =>  ['PAR','RN'],
				#relationTypes    => [ 'PAR', 'CHD', 'RB', 'RN' ],
			},
		);

		if ( $return_ref eq 'undefined' ) {
			print "\n The CUI/term does not exist";
			
			return 'undefined';
		}
		elsif ( $return_ref eq 'empty' ) {
			print "\n No information found for $cui in current Source/s";
			if($tflag == 1)
			{
				open(OUT,">>","output.txt") or die("Error: cannot open file 'output.txt'\n");
				print OUTPUT "-1<>$source<>$destination\n";
				close OUT;
			}
						
			
			
			return 'empty';
		}
		else {

#$parents_ref = $return_ref;#changed parents_ref to return_ref due to "odd" error
			return $return_ref;
		}

		#	print "\nhash returned by ws : $parents_ref";

	}

=head2 printHoH

This subroutines prints the current contents of hash of hash

=cut

	sub printHoH {

		my $hoh = shift;
		my %hoh = %$hoh;

		msg( "\nin printHoH : Graph is :", $verbose );
		foreach my $ngram ( keys %hoh ) {
			msg( "\n******************************************", $verbose );
			msg( "\n" . $ngram . "{",                            $verbose );
			foreach my $word ( keys %{ $hoh{$ngram} } ) {
				msg( "\n",                               $verbose );
				msg( $word . "=>" . $hoh{$ngram}{$word}, $verbose );
			}
			msg( "\n}", $verbose );

		}

	}
	
undef %node_cost;
undef %Graph;
undef @sources;
undef @relations;
undef @directions;	

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
