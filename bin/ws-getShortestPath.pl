#!/usr/bin/env perl


#---------------------------PERLDOC STARTS HERE------------------------------------------------------------------

=head1 NAME

ws-getShortestPath

=cut

#---------------------------------------------------------------------------------------------------------------------

=head1 SYNOPSIS

=head2 Basic Usuage

=pod

perl ws-getShortestPath.pl -verbose -sources SNOMEDCT,MSH --rels PAR,CHD --config configfilename 

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
C1879289 C1616556

C0015392 C0015392
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

sub GetParents::read_object which reads hash reference object passed to this
sub and fetches the required parents' information.

sub GetParents::format_object calls appropriate functions like format_homogenous_hash,
format_scalar, format_homogenous_array depending on the object reference it is called with.
format_homogenous_hash,format_scalar and format_homogenous_array are subroutines which 
read the objects they are called with and fetch the desired information.

=item package ConnectUMLS

sub ConnectUMLS::get_pt to get the proxy ticket using a web service.

sub ConnectUMLS::connect_umls to connect to UMLS by sending username 
and password and getting back a proxy ticket.

=item package ValidateTerm

sub ValidateCUI::validateTerm to accepts an input and validates it 
for as valid or invalid CUI or a term.

=item package GetUserData

sub GetUserData::getUserDetails to get username and password from the user.

=item package Query

sub Query::runQuery which takes method name, service and other parameters as argument and calls the web service. 
It also displays the information received from the web service and other error messages. 

=item package FindPaths

sub FindPaths::find_paths which uses a Graph module from CPAN and creates a graph
using the concepts and their parent concepts. It finds shortest path between two
input concepts and displays the path. 

=back

=cut

#---------------------------------------------------------------------------------------------------------------------------

#------------------------------PERLDOC ENDS HERE------------------------------------------------------------------------------


###############################################################################
##########  CODE STARTS HERE  #################################################
#use lib "/home/mugdha/UMLS-HSO/UMLS-HSO/WebService-UMLSKS-Similarity/lib";

use strict;
use warnings;
use SOAP::Lite;
use Term::ReadKey;
use WebService::UMLSKS::GetUserData;
use WebService::UMLSKS::ValidateTerm;
#use WebService::UMLSKS::FindPaths;
use WebService::UMLSKS::Query;
use WebService::UMLSKS::ConnectUMLS;
use WebService::UMLSKS::GetParents;
use WebService::UMLSKS::Similarity;
use WebService::UMLSKS::MakeGraph;
use WebService::UMLSKS::GetCUIs;
use Log::Message::Simple qw[msg error debug];

#use get_all_associatedCUIs;
use Getopt::Long;
#use SOAP::Lite +trace => 'debug';
no warnings qw/redefine/;


#Program that returns the shortest path between two concepts using UMLS database.

# Author :			 Mugdha
# Reference:         Program provided by Olivier B., NLM.


# This is a verbose variable which is set using the command line argument.
# This is set to true if you use --verbose option.
# This is set to false if you use --noverbose option.

my $verbose = '';
#GetOptions( 'verbose!' => \$verbose );

my $log_file = '';
my $patterns_file = '';
my $sources = '';
my $relations = '';
my $similarity;
my $config_file = '';
my $login_file = '';

#GetOptions( 'verbose!' => \$verbose );

GetOptions( 'verbose:i' => \$verbose , 'sources=s' => \$sources , 'rels=s' =>\$relations,
 'config=s' =>\$config_file, 'log=s' => \$log_file, 'login=s' => \$login_file ,'patterns=s',\$patterns_file);

# Reference for use of Log package
# http://perldoc.perl.org/Log/Message/Simple.html#msg(%22message-string%22-%5b%2cVERBOSE%5d)


if($log_file ne '' && $verbose eq 1){

open (LOG , '>>', $log_file);


$Log::Message::Simple::MSG_FH     = \*LOG;
$Log::Message::Simple::ERROR_FH   = \*LOG;
$Log::Message::Simple::DEBUG_FH   = \*LOG;

# Following code to print time and date in readable form is taken from following source 
#http://perl.about.com/od/perltutorials/a/perllocaltime_2.htm

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";

# Code from source ends here

debug("\n*********************************\n Log written on :
$theTime\n************************************", $verbose); 

}

if(defined $config_file && $config_file ne "")
{
	 $similarity = WebService::UMLSKS::Similarity->new({"config" => $config_file});
	
}

else
{
if($sources eq "" && $relations eq "")
{
	# use default things
	msg("\n creating default object of similarity", $verbose);
	 $similarity = WebService::UMLSKS::Similarity->new();
}
else{

if(defined $sources && defined $relations)
{
	# user specified sources through command line
	my @source_list = split ("," , $sources);
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLSKS::Similarity->new({"sources" =>  \@source_list,
												    	 "rels"   =>  \@relation_list }	);
	
	#$ConfigurationParameters{"SAB"} = \@sources_list;
}
elsif(defined $relations )
{
	# user specified rels through command line
	my @relation_list = split ("," , $relations);
	 $similarity = WebService::UMLSKS::Similarity->new({ "rels"   =>  \@relation_list });
	
	#$ConfigurationParameters{"REL"} = \@relation_list;
}
elsif(defined $sources)
{
	my @source_list = split ("," , $sources);
	 $similarity = WebService::UMLSKS::Similarity->new({"sources" =>  \@source_list}	);
	
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
my  $allowable_pattern_regex = '';
	
# Creating object of class GetUserData 
my $g       = WebService::UMLSKS::GetUserData->new;
my $service = "";

if(defined $login_file && $login_file ne "")
{
	# Login details specified through the file
	# call sub getService using object of GetUserData
	# Receive a $service object if the user is a valid user.
	
	my $username = "";
	my $pwd = "";
	
	open( LOGIN, $login_file )
		  or die("Error: cannot open configuration file '$login_file'\n");

		my @login_details = <LOGIN>;
		foreach my $detail (@login_details){
			
			#msg( "\n $detail", $verbose);
			$detail =~ /\s*(.*)\s*::\s*(.*?)$/;
			#print "\n $1 \t $2";
			my $detail_name = $1;
			my $detail_value = $2;
			chomp($detail_value);
			chomp($detail_name);
			if($detail_name ne "" && $detail_value ne ""){
				if($detail_name =~ /\b[Uu]sername\b/){
				$username = $detail_value;
				}
				if($detail_name =~ /\b[pP]assword\b|\b[Pp]wd\b/){
				$pwd = $detail_value;
				}
			}
			else
			{
				print "\n Invalid login file";
				exit;
			}
			
		}
	
	 $service = $g->getService($verbose, $username, $pwd);
	
		
}

else
{
# call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

 $service = $g->getUserDetails($verbose);
	
}



# User enetered wrong username or password.

if ( $service == 0 ) {
	$continue = 0;
}


# If allowable patterns are specified by user using the patterns_file then,
# set the regex from the file

if(defined $patterns_file && $patterns_file ne "")
{

	open( PATTERN, $patterns_file )
		  or die("Error: cannot open configuration file '$patterns_file'\n");
	
	my @p = <PATTERN>;
	my $allowable_regex = $p[0];
	 msg ("\n regex from file is : $allowable_regex", $verbose);
	chomp($allowable_regex);
	$allowable_regex =~ s/\s*//g;
	#my $regex;
	if($allowable_regex =~ m/^\// && $allowable_regex =~ m/\/$/)
		{
				msg( "\n regex is valid",$verbose);
				$allowable_regex =~  m/^\/(.*)\/$/;
				$allowable_pattern_regex = $1;
				msg ("\n regex extracted is : $allowable_pattern_regex", $verbose);
		}
		else
		{
			print "\n You entered Invalid regex in patterns file";
			exit;
			
		}
	#$allowable_pattern_regex =~ chop($allowable_pattern_regex);
	#$allowable_pattern_regex =~ s/^\///g;
	msg("allowable path regex: $allowable_pattern_regex",$verbose);

}

# Else, use the defualt regex representing the default set of allowable patterns

else
{
	
   # This regex is formed using the allowed paths' patterns given in HSO paper
   # Here 1, denotes upward arrow/vector, 2 denotes downward arrow and 3 denoted
   # horizontal arrows.
	
   $allowable_pattern_regex = '\b1+\b|\b1+2+\b|\b1+3+\b|\b1+3+2+\b|\b2+\b|\b2+3+\b|\b3+2+\b|\b3+\b';
}



# Creating object of query and passing the method name along with parameters.

my $query = WebService::UMLSKS::Query->new;

# Creating Connect object to call sub get_pt while forming a query.

my $c = WebService::UMLSKS::ConnectUMLS->new;

# Creating GetParents object to get back the parents of input terms.

my $read_parents = WebService::UMLSKS::GetParents->new;

# Creating  GetCUIs object to get back CUIs related to terms.

my $get_CUIs = WebService::UMLSKS::GetCUIs->new;

# Creating object of MakeGraph

my $form_graph = WebService::UMLSKS::MakeGraph->new;

my $proxy_ticket = $c->get_pt();

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

	if ( $term1 =~ /stop/i ) {
		exit;
	}


	# Validate the term by passing it to the sub validateTerm which belongs to class getTerm.
	# Create object of class getTerm to access the sub validateTerm.

		my $valid        = WebService::UMLSKS::ValidateTerm->new;
		my $isvalid_input1 = $valid->validateTerm($term1);
		my $isvalid_input2 = $valid->validateTerm($term2);

	  # Depending on the value returned by validateTerm form a query for UMLSKS.

		my @allCUIOfTerm1 = ();
		my @allCUIOfTerm2 = ();

		# If the inputs are invalid, accepts new input
		if($isvalid_input1 eq 'invalid') 
		{
			print "\n* Your first input is not a valid CUI";
			next;
		}
		elsif($isvalid_input2 eq 'invalid') 
		{
			print "\n* Your first input is not a valid CUI";
			next;
		}
		
		# else inputs are either valid CUIs or terms
		else
		{
			
			# Check if input1 is term or CUI
							
			# If the input entered by user is term, call findCUIByExact webservice,
			# to get back the CUI.
			if($isvalid_input1 eq 'term')
			{
				my %CUI_ref = %{$get_CUIs->get_CUI_info($service,$term1)};
				if(!%CUI_ref)
				{
					print "\n Term $term1 does not exist in database.";
					next;
				}
				else
				{
					print "\n Informtion about first input term : $term1 ->";
					foreach my $c (keys %CUI_ref){
						push(@allCUIOfTerm1,$CUI_ref{$c});
						print "\nPreffered term : $c and CUI : $CUI_ref{$c}";
					}
										
				}
			}
			elsif($isvalid_input1 eq 'cui'){
					print "\nFirst input is a CUI: $term1";
					push(@allCUIOfTerm1,$term1);
			}
			
			# Check if input2 is term or CUI
							
			# If the input entered by user is term, call findCUIByExact webservice,
			# to get back the CUI.
			if($isvalid_input2 eq 'term')
			{
				my %CUI_ref = %{$get_CUIs->get_CUI_info($service,$term2)};
				if(!%CUI_ref)
				{
					print "\n Term $term2 does not exist in database.";
					next;
				}
				else
				{
					print "\n Informtion about second input term : $term2 ->";
					foreach my $c (keys %CUI_ref){
						push(@allCUIOfTerm2,$CUI_ref{$c});
						print "\nPreffered term : $c and CUI : $CUI_ref{$c}";
					}
										
				}
			}
			elsif($isvalid_input2 eq 'cui'){
					print "\nSecond input is a CUI: $term2";
					push(@allCUIOfTerm2,$term2);
			}			
		}
		
		my $t1 = "";
		my $t2 = "";
		
		
		#print "\n arrays are \n cuis of term 1 : @allCUIOfTerm1 cuis of term2 : @allCUIOfTerm2";
		
		if($#allCUIOfTerm1 == 0 && $#allCUIOfTerm2 == 0){
		#	print "\nJust one CUI for both terms";
			msg("Both the terms have just one CUI",$verbose);
						
			# Calling formGraph to make a graph and find the allowable shortest path
	
			 $t1 = $allCUIOfTerm1[0];
			 $t2 = $allCUIOfTerm2[0];
			
			# Check if both the inputs are same.
		
			msg("\n before calling form grpah : regex: $allowable_pattern_regex", $verbose);
			my $return_val = $form_graph->form_graph($t1,$t2,$service, $verbose, \@sources, \@relations,$allowable_pattern_regex);
			if($return_val eq 'same'){
			next;
			}			
		
		}
		
		else
		{
			#print "\n cuis of 1 : @allCUIOfTerm1, cuis of 2 : @allCUIOfTerm2";
			print "\n Do you want to calculate Semantic Relatedness between all the combinations of the CUIs (y/n):";
			my $option = <>;
			chomp($option);
			#print "\n option is : $option";
			if($option eq 'y'){
				#print "\n inside for loops";
				my $i;
				my $j;
				for($i = 0; $i <= $#allCUIOfTerm1; $i++){
					
					for ($j = 0 ; $j <= $#allCUIOfTerm2; $j++){
						#print "\n in both loops";
						my $t1 = $allCUIOfTerm1[$i];
						my $t2 = $allCUIOfTerm2[$j];
						print "\n\nterm 1 : $t1 term 2 : $t2";
						my $return_val = 
						$form_graph->form_graph($t1,$t2,$service, $verbose, \@sources, \@relations, $allowable_pattern_regex);
						if($return_val eq 'same'){
							print "\n $t1 and $t2 are same";
							next;
						}	
					}
				
				}
			
				
			}
			else
			{
				#print "\n cuis of term 1 ; @allCUIOfTerm1, cuis of term 2 @allCUIOfTerm2";
				
				 $t1 = $allCUIOfTerm1[0];
			 	 $t2 = $allCUIOfTerm2[0];
			
				my $return_val = $form_graph->form_graph($t1,$t2,$service, $verbose, \@sources, \@relations,$allowable_pattern_regex);
				if($return_val eq 'same'){
					next;
				}			
				
			}
		}
			



	}
	
}

#-------------------------------PERLDOC STARTS HERE-------------------------------------------------------------


=head1 SEE ALSO 

ValidateCUI.pm  GetUserData.pm  Query.pm  ConnectUMLS.pm GetParents.pm FindPaths.pm

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

