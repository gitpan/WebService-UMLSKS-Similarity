
=pod

=head1 NAME

get_validate_CUI - Get the query CUI from calling program and validate the CUI.

=head1 SYNOPSIS

=head2 Basic Usage

  use WebService::UMLS::get_validate_CUI;  
  
  print "\nEnter query CUI:";
  my $cui        = <>;  
  my $valid      = new ValidateCUI;
  my $isvalid_CUI = $valid->validateCUI($cui);


=head1 DESCRIPTION

This module has package ValidateCUI which has two subroutines 'new' and 'validateCUI'.
This module takes the query CUI from calling program and validates it.
It returns values depending on whether the query is valid or invalid CUI.


=head2 Methods

new: This sub creates a new object of ValidateCUI. 

validateCUI: This sub takes the query CUI from calling program and validates it.
It returns '2' if CUI is valid CUI.
In the case of invalid CUI, it returns '10'.


=head1 SEE ALSO

authenticate_user.pm  get_user_details.pm  run_query.pm  ws-getUMLSInfo.pl 

=over

=cut


###############################################################################
##########  CODE STARTS HERE  #################################################

use warnings;
use strict;

# This is ValidateTerm package which has two subroutines 'new' and 'validateTerm'.
package ValidateCUI;

# This sub creates a new object of ValidateTerm
sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}


# This sub tekes query CUI as an argument and validates it.
# It returns 2 if term is a valid CUI.
# It also displays error messages if the CUI is invalid.
# A valid CUI is a string thats starts with capital 'C' and is 
# followed by seven digits and all digits are not zero at one time
# i.e., C0000000 is a invalid CUI.


sub validateCUI {

	my $self = shift;
	my $cui = shift;
	if ( $cui =~ /^[cC][0-9]/ ) {
		if ( $cui =~ /^C\d{7}$/ ) {
			if ( $cui =~ /C0000000/ ) {
				# It is a invalid CUI.
				return 10;
			}
			else {

				# It is a valid CUI.
				return 2;
			}
		}
		else {
			# It is a invalid CUI.
			return 10;
		}
	}
	else {

		# It is a invalid CUI.
		return 10;
	}

}

1;

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------

=back

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
