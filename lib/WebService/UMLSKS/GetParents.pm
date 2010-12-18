
=head1 NAME

WebService::UMLSKS::GetParents - Fetches all the parent concepts for the input concept.

=head1 SYNOPSIS

=head2 Basic Usage

    use WebService::UMLSKS::GetParents;
    
    my $parents_ref = call_getconceptproperties($cui);# parents_ref is a hash reference
    my $read_parents = new GetParents;
    # $ref is a reference of an array of all parents' CUI for the input cui.
    my $ref  = $read_parents->read_object( $parents_ref );   
	   


=head1 DESCRIPTION

This module has package GetParents which has subroutines 'new', 'read_object','extract_object_class', 
'format_object', 'format_homogeneous_hash', 'format_scalar', format_homogeneous_array.


=head1 SUBROUTINES

The subroutines are as follows:


=cut

###############################################################################
##########  CODE STARTS HERE  #################################################



use SOAP::Lite;
use strict;
use warnings;
no warnings qw/redefine/;

package WebService::UMLSKS::GetParents;
our $ConceptInfo_ref;

my %ConceptInfo;
my @parents;
my $indentation;

=head2 new

This sub creates a new object of GetParents.

=cut

sub new {
	my $class = shift;
	my $self  = {};

	#print "in new in display_info";
	bless( $self, $class );
	return $self;
}

=head2 read_object

This sub reads hash reference object passed to this
sub and fetches the required parents' information.

=cut

sub read_object {

	my $self        = shift;
	my $object_refr = shift;
	@parents = ();
	#my $return_ref =
	format_object($object_refr);
	chomp(@parents);

	$ConceptInfo_ref = \%ConceptInfo;

# The following code snippet to delete duplicate elements from an array is referred from
# perfaq4 and is modified according to need. For details refer :
# http://perldoc.perl.org/perlfaq4.html#How-can-I-remove-duplicate-elements-from-a-list-or-array%3f
# The first time the loop sees an element, that element has no key in %Seen .
# The next time the loop sees that same element, its key exists in the hash and the value for that key
# is true (since it's not 0 or undef), so the skip that iteration and the loop goes
# to the next element.

	my @unique = ();
	my %seen   = ();
	foreach my $elem (@parents) {
		if ( $seen{$elem}++) {

		}
		else {
			unless($elem eq '1'){
				push( @unique, $elem );
			}
			
		}
	}

	# Code snippet from perlfaq4 ends here.
	
	my $parents_ref = \@unique;
	if(defined $parents_ref){
		#print "\n parents are @unique";
		return $parents_ref;		
	}
	else{
		print "\n No parents found";
		return 'empty';
	}
	
}


# This sub formats the structures returned by the web service. It calls
# the appropriate subroutines depending on the type of structure
# it is called with. If the input reference is a hash reference it calls 
# format_homogenous_hash method. If input is array reference,
# it calls format homogenous array and simillarly for scalar input 
# reference it calls format_scalar.

=head2 format_object

This sub calls appropriate functions like format_homogenous_hash,
format_scalar, format_homogenous_array depending on the object reference it is called with.

=cut

sub format_object {

	my $object_ref = shift;

	#print "in format object";

	unless ( defined $object_ref ) {
		return 'undefined';
	}
	else {
		if ( $object_ref =~ /HASH/o ) {
			return format_homogeneous_hash($object_ref);
		}
		elsif ( $object_ref =~ /ARRAY/o ) {
			return format_homogeneous_array($object_ref);
		}
		elsif ( $object_ref =~ /SCALAR/o ) {
			return format_scalar($object_ref);
		}
		elsif ( defined $object_ref ) {
			return $object_ref;
		}
		else {
			return 'term is not present';
		}
	}
}


=head2 indent

This sub is used for indentation.

=cut

sub indent {

	#print "\n";
	my $number = shift;
	my $i;
	for ( $i = 0 ; $i < $number ; $i++ ) {
	#	print " *i ";
	}

}


=head2 format_scalar

This sub formats scalar object.

=cut

sub format_scalar {

	my $scalar_ref = shift;

	#print "in format_scalar";
	print "*s".$$scalar_ref;
	return format_object($$scalar_ref);

}

=head2 format_homogeneous_hash

This sub formats hash.

=cut

sub format_homogeneous_hash {
	#$indentation++;
	my $hash_ref = shift;

	#print "in format_hash";
	my @incl_rows = ();

	my $flag   = 0;
	my $flag2  = 0;
	my $t_flag = 0;
	my $c_flag = 0;
	my $current_term;
	my $current_cui;
	my $q_cui;
	my $q_term;

	#print "\n";
	#indent($indentation);

	#print "hash{";
	foreach my $att ( keys %$hash_ref ) {


  # Follwing regular expression is used to display just the required information
  # and discard the unnecessary information returned by the UMLSKS.
		if (
			$att =~
/\brelease\b|\bkey\b|\bempty\b|\bperformance\b|\bRAs\b|\bCAs\b|\bSTYs\b|\bdefs\b|\bterms\b|\bSGs\b|
\bSAB\b|\btype\b|\bCOCs\b|\bCXTs\b|\bcontentClass\b|\bSATUI\b|\bDefinition\b|\bAUI\b|\bATUI\b|\brelSources\b|
\bRelation\b|\bSL\b|\bqueryInput\b|\bConcept\b|\bcontents\b/
		  )
		{
			
			#print nothing
			
		}	
		
		else {

# Check for rel key in hash to select the needed part in relation hash.
			if ( $att =~ /rel/ ) {

				$flag = 1;

				

			}

			if ( $flag == 1 ) {

				if ( $att =~ /rel|RUI|type|autoGen|SRUI|directionality|relA/ ) {

					#do nothing
				
				}

				else {
					if ( $att =~ /CN/ ) {
						$current_term = $hash_ref->{$att};
						$t_flag       = 1;

					}
					else {
						if ( $t_flag == 1 ) {

			 				# checking if att is a valid CUI
			 				if($hash_ref->{$att} =~ /^C/)
			 				{
							$current_cui = $hash_ref->{$att};
							if(defined $current_cui){ #c 1
							unless ($current_cui ~~ %ConceptInfo){
							$ConceptInfo{$current_cui} = $current_term;
							}
							}
							}

							
						}

						push( @parents, $hash_ref->{$att} );
					}

				}

			}
		}
			
			if ( $att =~ /CN/ ) {				
					
					$q_term = $hash_ref->{$att};
					#print "\n got xtra term : $q_term";
					$c_flag = 1;
				}
				elsif( $att =~ /CUI|cui|Cui/){
					if($c_flag == 1){
						$q_cui = $hash_ref ->{$att};
						#print "\n got xtra cui : $q_cui";
						unless($q_cui ~~ %ConceptInfo){
							$ConceptInfo{$q_cui} = $q_term;
						}
						
					}
				}
				

						
		

	  #Follwing regular expression is used to get just the required information.
		if ( $att =~ /contents|CUI|Concept|rels|Relation|relSources/ ) {

			push @incl_rows, $att, format_object( $hash_ref->{$att} );

		}
	}

	return @incl_rows;

}

=head2 format_homogeneous_array

This sub formats array.

=cut

sub format_homogeneous_array {
	#$indentation++;
	my $array_ref = shift;

	#print "in format_array";
	my @incl_rows = ();

	#indent($indentation);

	foreach my $val (@$array_ref) {#c2

		push @incl_rows, format_object($val);

	}

	@incl_rows = ('no values') unless @incl_rows;

	return @incl_rows;
}

=head2 extract_object_class

This sub removes exact reference of object.

=cut

sub extract_object_class {
	my $object_ref = shift;

	# remove exact reference
	$object_ref =~ s/\(0x[\d\w]+\)$//o;

	my ( $class, $type ) = split /=/, $object_ref;

	my $res = undef;
	if ($type) {
		$res = $class;
	}
	else {
		$res = $object_ref;
	}

	return $res;
}

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

## =back spurious back removed by tdp


=head1 SEE ALSO

ValidateCUI.pm  GetUserData.pm  Query.pm  ws-getShortestPath.pl FindPaths.pm

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
