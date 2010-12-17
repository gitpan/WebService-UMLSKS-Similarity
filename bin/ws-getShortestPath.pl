#!/usr/bin/env perl


#---------------------------PERLDOC STARTS HERE------------------------------------------------------------------

=head1 NAME

Get Shortest Path

=cut

#---------------------------------------------------------------------------------------------------------------------

=head1 SYNOPSIS

=head2 Basic Usuage

=pod

perl getShortestPath.pl -verbose -sources SNOMEDCT,MSH --rels PAR,CHD --config configfilename 

--verbose: Sets verbose flag to true and thus displays all the authentication information for the user.

-sources : UMLS sources can be specified by providing list of sources seperated
by comma. These sources will be used to query and retrieve the information.

-rels :  UMLS relations can be specified by providing list of relations seperated
by comma. These relations will be used to query and retrieve the information.

-config : Instead of providing sources and relations on command line, they can be
specified using a configuration file, which can be provided with this option.
It takes complete path and name of the file
Follwing is a sample output

=over

=item Enter username to connect to UMLSKS:mchoudhari

=item Enter password: 

=item Enter first query CUI:C0229962

=item Enter second query CUI:C1623497

=item UMLS Source(s) used: SNOMED-CT

=item UMLS Relation(s) used: PAR/CHD

=item Source is : C0229962, Destination is: C1623497

=item path is->Body part (C0229962)->Body Regions (C0005898)->Anatomic structures (C0700276)->Physical anatomical entity (C0506706)->Body structure (C1268086)->SNOMED CT (C1623497)

=item Enter first query CUI:stop

=back


=head1 DESCRIPTION


This program authenticates user by asking for valid username and password to connect to UMLSKS. Once the user is 
authenticated program takes two terms from the user and finds the shortest path (semantic 
distance) between those two concepts using the heirarchical 
structure of the UMLSKS Metathesaurus database. The program queries SNOMED-CT database with the CUIs user enters and displays the shortest
path along with the concepts through which the two inputs are connected.
It also displays the UMLS relations and sources used to find the path.
 
=cut

=head2 Modules/Packages

=pod 

This program uses following packages:

=over
 
=item package GetParents

->sub GetParents::read_object which reads hash reference object passed to this
sub and fetches the required parents' information.

->sub GetParents::format_object calls appropriate functions like format_homogenous_hash,
format_scalar, format_homogenous_array depending on the object reference it is called with.
format_homogenous_hash,format_scalar and format_homogenous_array are subroutines which 
read the objects they are called with and fetch the desired information.

=item package Connect

->sub Connect::get_pt to get the proxy ticket using a web service.


->sub Connect::connect_umls to connect to UMLS by sending username 
and password and getting back a proxy ticket.

=item package ValidateCUI

->sub ValidateCUI::validateCUI to accepts an input and validates it 
for as valid or invalid CUI.

=item package GetUserData

->sub GetUserData::getUserDetails to get username and password from the user.

=item package Query

->sub Query::runQuery which takes method name, service and other parameters as argument and calls the web service. 
It also displays the information received from the web service and other error messages. 

=item package FindPaths

->sub FindPaths::find_paths which uses a Graph module from CPAN and creates a graph
using the concepts and their parent concepts. It finds shortest path between two
input concepts and displays the path. 

=back

=cut

#---------------------------------------------------------------------------------------------------------------------------
=pod 


=head1 SEE ALSO 

get_validate_CUI.pm  get_user_details.pm  run_query.pm  autheticate_user.pm get_parents.pm find_shortest_path.pm

=cut

#------------------------------PERLDOC ENDS HERE------------------------------------------------------------------------------


###############################################################################
##########  CODE STARTS HERE  #################################################

#use lib "/home/mugdha/workspace/thesis_modules/lib";
use strict;
use warnings;
use SOAP::Lite;
use Term::ReadKey;
use WebService::UMLS::get_user_details;
use WebService::UMLS::get_validate_CUI;
use WebService::UMLS::find_shortest_path;
use WebService::UMLS::run_query;
use WebService::UMLS::authenticate_user;
use WebService::UMLS::get_parents;
use WebService::UMLS::Similarity;
#use get_all_associatedCUIs;
use Getopt::Long;
#use SOAP::Lite +trace => 'debug';


#Program that returns the shortest path between two concepts using UMLS database.

# Author :			 Mugdha
# Reference:         Program provided by Olivier B., NLM.


# This is a verbose variable which is set using the command line argument.
# This is set to true if you use --verbose option.
# This is set to false if you use --noverbose option.

my $verbose = '';
#GetOptions( 'verbose!' => \$verbose );


my $sources = '';
my $relations = '';
my $similarity;
my $config_file = '';

#GetOptions( 'verbose!' => \$verbose );

GetOptions( 'verbose:i' => \$verbose , 'sources=s' => \$sources , 'rels=s' =>\$relations, 'config=s' =>\$config_file );

if(defined $config_file)
{
	 $similarity = WebService::UMLS::Similarity->new({"config" => $config_file});
	
}

else
{
if($sources eq "" && $relations eq "")
{
	# use default things
	print "\n creating default object of similarity";
	 $similarity = WebService::UMLS::Similarity->new();
}
else{

if(defined $sources && defined $relations)
{
	# user specified sources through command line
	my @source_list = split ("," , $sources);
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLS::Similarity->new({"sources" =>  \@source_list,
												    	 "rels"   =>  \@relation_list }	);
	
	#$ConfigurationParameters{"SAB"} = \@sources_list;
}
elsif(defined $relations )
{
	# user specified rels through command line
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLS::Similarity->new({ "rels"   =>  \@relation_list });
	
	#$ConfigurationParameters{"REL"} = \@relation_list;
}
elsif(defined $sources)
{
	my @source_list = split ("," , $sources);
	 $similarity = WebService::UMLS::Similarity->new({"sources" =>  \@source_list}	);
	
}

}

}
my @sources = @{$similarity->{'SAB'}};
my @relations = @{$similarity->{'REL'}};



# This is used to continue asking for the new term to user unless you enter 'stop'.

my $continue = 1;
my $object_ref;

# Declaring hash ParentInfo to store parent CUIs' information in following format:
# ParentInfo     : hash { CUI  =>  (list of parents CUIs)
#                         CUI  =>   (list of parents CUIs)
#                         .........
#                         }

my %ParentInfo ;

# Declaring ListCUI : queue/ list of CUIs elligible for parent search

my @ListCUI = ();

# Creating object of class GetUserData and call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

my $g       = GetUserData::new GetUserData;
my $service = $g->getUserDetails($verbose);

# User enetered wrong username or password.

if ( $service == 0 ) {
	$continue = 0;
}

# Creating object of query and passing the method name along with parameters.

my $query = Query::new Query;

# Creating Connect object to call sub get_pt while forming a query.

my $c = ConnectUMLS::new ConnectUMLS;

# Creating GetParents object to get back the parents of input terms.

my $read_parents = GetParents::new GetParents;

# Creating  FindPaths object to get back shortest path between two input terms.

my $get_paths = FindPaths::new FindPaths;

# Creating  GetAllCUIs object to get back all the associated CUIs related to 
# two input terms.

#my $get_allCUIs = new GetAllCUIs;


while ( $continue == 1 ) {

	# After the authentication, accept a first query term or CUI from the user.

	print "\nEnter first query CUI:";
	my $term1 = <>;

	# Remove white spaces.

	chomp($term1);
	# If user enters 'stop', exit the program.
	if ( $term1 =~ /stop/i ) {
		exit;
	}

	# Else continue with asking the new query term.

	else {

	# After the authentication, accept a first query term or CUI from the user.

	print "\nEnter second query CUI:";
	my $term2 = <>;

	# Remove white spaces.

	chomp($term2);

	

		my $qterm1 = $term1;

		#print "term1 is $term1";
		my $qterm2 = $term2;

		#print "term2 is $term2";

# Validate the term by passing it to the sub validateTerm which belongs to class getTerm.
# Create object of class getTerm to access the sub validateTerm.

		my $valid       = ValidateCUI::new ValidateCUI;
		my $isvalid_CUI1 = $valid->validateCUI($term1);
		my $isvalid_CUI2 = $valid->validateCUI($term2);

	  # Depending on the value returned by validateTerm form a query for UMLSKS.

		my $cui1 = ' ';
		my $cui2 = ' ';
	
	#	my @allCUIOfTerm1 = ();
	#	my @allCUIOfTerm2 = ();
	
		my $proxy_ticket = $c->get_pt();


		if($isvalid_CUI1 == 10 || $isvalid_CUI2 == 10)
		{
			print "\n* Your input(s) are not valid CUIs";
			next;
		}

		$qterm1 = $term1;
		#print "\nnow cui1 is $cui1";
		$isvalid_CUI1 = 2;


# If the second input entered by user is term, call findCUIByExact webservice 
# through the sub  call_findCUIByExact, to get back the CUI.


		$qterm2 = $term2;
		#print "\nnow cui2 is $cui2";
		$isvalid_CUI2 = 2;


# ValidateTerm returns $isTerm_CUI1 = 2 for first input, if the input entered 
# by the user is a valid CUI.
# Call getConceptProperties web service and get back the information.

		if ( $isvalid_CUI1 == 2 ) {
			
			#print "\n term1 cui is $qterm1 ";
			# Push cui in list ListCUI.
			push( @ListCUI, $qterm1 );

			#my $pref1 = call_getconceptproperties( $term1, $cui1 );
			#print "\n  Query term:$term2";
			#my $object_f = $read_parents->read_object($pref1);

		}

# ValidateTerm returns $isTerm_CUI2 = 2 for second input, if the input entered
# by the user is a valid CUI. 
# Call getConceptProperties web service and get back the information.

		if ( $isvalid_CUI2 == 2 ) {
			
			#print "\n term2 cui is $qterm2 ";
			# Push cui in list ListCUI.
			push( @ListCUI, $qterm2 );

			#my $pref2 = call_getconceptproperties( $term2, $cui2 );
			#print "\n  Query term:$term2";
			#my $object_f = $read_parents->read_object($pref2);

		}
		

# Algorithm to store parents information:
# 1.Add input CUIs to ListCUI if CUI does not exist in ListCUI.
# 2. while ListCUI is not empty {
#    a.Take first entry from queue and call getParents() on it.
#    b.Add an entry in ParentInfo with the query CUI and parents returned by webservice.
#    c.Add parents to ListCUI if not already present.
#    }
       my @seen = ();
		until ( @ListCUI == 0 ) {
			my $item = pop(@ListCUI);		
			push (@seen , $item);
			my $ref  =
			  $read_parents->read_object( call_getconceptproperties($item) );
			  if (defined($ref))
			  {
			my @parent_array = @$ref;

# deleting the input cui from the list refer : http://sial.org/blog/2007/08/delete_element_from_array.html
			for my $i ( 0 .. $#parent_array ) {
				if ( $parent_array[$i] eq $item ) {
					delete $parent_array[$i];
				}
				else {

					# push it in ListCUI if not already present.
					#if($parent_array[$i])
					#print "\nparent[$i] = $parent_array[$i]";
					if($parent_array[$i] ~~ @seen)
					{
						#print "\n $parent_array[$i] already seen";
					}
					else
					{
						 # print "\n $parent_array[$i] not in ListCUI so push it";
						push(@ListCUI, $parent_array[$i]);
					}

				}
			}
			#print "\n";

			#print "@parent_array";
			# add entry in parentinfo hash
			$ParentInfo{$item} = [@parent_array];
			}
			#elsif ($item eq 'C1623497')
			#{
			#	my @root = ('root');
			#	$ParentInfo{$item} = [@root];
			#}
			#else
		#{
		#	my @undefined = ('undefined');
		#	$ParentInfo{$item} = [@undefined];
		#}

		}
	print "\n UMLS Source(s) used: @sources\n";
	print "\n UMLS Relation(s) used: @relations\n";

	my $ParentInfo_ref = \%ParentInfo;	
	# Call findShortestPath with the parameter as parentInfo.
	$get_paths->find_paths($ParentInfo_ref,$qterm1,$qterm2);

	}
	
#	foreach my $k ( keys( %ParentInfo) ) { 
#              delete ($ParentInfo{$k});
#	}

}

#C0229962, C1623497 

sub call_getconceptproperties {

	my $cui = shift;
	my $parents_ref;

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
			
			SABs => [(@sources)],
			#SABs => [qw( SNOMEDCT )],
			includeConceptAttrs  => 'false',
			includeSemanticTypes => 'false',
			includeTerminology   => 'false',

			#includeDefinitions   => 'true',
			includeSuppressibles => 'false',

			includeRelations => 'true',
			relationTypes    => ['PAR'],
		},
	);

	return $parents_ref;
}

#good reference : perlmeme.org, perl101.org, perlmonks.org


#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


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

