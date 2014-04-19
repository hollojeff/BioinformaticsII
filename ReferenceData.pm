#!/usr/bin/perl
#Name: Ginny Devonshire
#Middle layer module: ReferenceData
#Includes: sub-routines to get reference data from the database

package ReferenceData;

use strict;

#=========================================================================================

#GetCodonData - notes

#gets codon usage reference data for the genome
#output used to populate a table on the detail web page
#summary page >> GetDetail >> CalcCodonFreq >> GetCodonData >> CalcCodonFreq >> GetDetail >> detail page

#input: database handle
#output: hash
#hash keys ~ codons, hash values ~ references to arrays
#array values ~ amino acid, genome frequency, genome ratio

#-----------------------------------------------------------------------------------------

#GetCodonData - manual test
#use DbiHandle;
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = GetCodonData($dbh);
#foreach my $codon(keys(%codons)) {
	#print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetCodonData($) {
	
	my ($dbh) = @_;	
	$dbh
		or die ("Unable to process request for codon reference data: unable to access database");
	
	#create and run a query to return the codon reference records including amino acid and genome stats
	my $sql = 
	"SELECT codon, one_letter_id, codon_freq, codon_ratio
	FROM codon";

	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct codon query");
	
	$sth->execute
		or die ("Unable to run codon query");

	#append each record to the return hash
	my %codons;
	while (my @row = $sth->fetchrow_array) {
		push @{$codons{@row[0]}}, @row[1], @row[2], @row[3]; 
	}
	
	if ($sth->rows > 0 && $sth->rows < 64) {
        	print ("Codon reference data incomplete.\n");
    	}
	
	if (0 == $sth->rows) {
		print ("No codons included in reference data.\n");
		#subroutine returns empty hash
    	}

	$sth->finish;	
	
	return %codons;

}

#=========================================================================================

#GetEnzymeData - notes

#gets restriction enzyme reference data 
#output used to populate a drop down box or radio buttons on the detail web page
#summary page >> GetDetail >> GetEnzymeData >> GetDetail >> detail page

#input: database handle
#output: hash
#hash keys ~ enzyme abbreviations, hash values ~ restriction sequences

#-----------------------------------------------------------------------------------------

#GetEnzymeData - manual test
#use DbiHandle;
#my $dbh = DbiHandle::GetDbHandle();
#my %enzymes = GetEnzymeData($dbh);
#foreach my $enzyme(keys(%enzymes)) {
#	print $enzyme, ", ", $enzymes{$enzyme}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetEnzymeData($) {

	my ($dbh) = @_;
	$dbh
		or die ("Unable to process request for restriction enzyme data: unable to access database");

	#create and run a query to return the enzyme reference records
	my $sql = 
	"SELECT re_name, restriction_seq
	FROM restriction_enzyme";
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct restriction enzyme query");

	$sth->execute
		or die ("Unable to run restriction enzyme query");

	#append each record to the return hash		
	my %enzymes;
	while (my @row = $sth->fetchrow_array) {
		$enzymes{@row[0]} = @row[1]; 
	}
	
	if (0 == $sth->rows) {
        	print ("No restriction enzymes included in reference data.\n");
		#subroutine returns empty hash
	}
	
	$sth->finish;
	
	return %enzymes;
	
}

#=========================================================================================

1;
