#!/usr/bin/env perl

#Program that connects to UMLSKS and queries the UMLS through the UMLSKS API to return information for an entered term or CUI.

# Author :			 Mugdha
# Reference:         Program provided by Olivier B., NLM.


use strict;
use warnings;
use SOAP::Lite;


#use lib "/home/mugdha/workspace/thesis_modules/lib";

use WebService::UMLSKS::GetUserData;
use WebService::UMLSKS::ValidateTerm;
use WebService::UMLSKS::Query;
no warnings qw/redefine/;


my $verbose = 1;

# Creating object of class GetUserData and call the sub getUserDetails.
# Receive a $service object if the user is a valid user.

my $g       = GetUserData->new;
my $service = $g->getUserDetails($verbose);


# Creating Connect object to call sub get_pt while forming a query.

my $c = ConnectUMLS::new ConnectUMLS;

print "\nEnter query term:";

	my $term = <>;

	# Remove white spaces.

	chomp($term);
	
	
# Validate the term by passing it to the sub validateTerm which belongs to class getTerm.
# Create object of class getTerm to access the sub validateTerm.

		my $valid      = ValidateTerm->new;
		my $isTerm_CUI = $valid->validateTerm($term);


 # Creating object of query and passing the method name along with parameters.

		my $query = Query->new;
		
		my $cui;

# Following sub describes the details like the method name to be called, term to be searched etc.
# Using default source SNOMECT to get the CUI back.

			$service->readable(1);
			$cui = $query->Query::runQuery(
				$service, $term,
				'findCUIByExact',
				{
					casTicket => $c->get_pt(),

		   # use SOAP::Data->type in order to prevent
		   # UTF-8 strings from being encoded into base64
		   # http://cookbook.soaplite.com/#internationalization%20and%20encoding
					searchString => SOAP::Data->type( string => $term ),
					language     => 'ENG',
					release      => '2009AA',
					SABs => [qw(SNOMEDCT)],
					includeSuppressibles => 'false',
				},
			);

print "\nCUI for term $term is : $cui\n";

# Serialization subroutines

# serialization -- non-Perl types / complex types

sub SOAP::Serializer::as_boolean {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'xsd:boolean', %$attr }, $value ];
}

sub SOAP::Serializer::as_ArrayOf_xsd_string {
	my ( $self, $value, $name, $type, $attr ) = @_;
	return [ $name, { 'xsi:type' => 'array', %$attr }, $value ];
}
