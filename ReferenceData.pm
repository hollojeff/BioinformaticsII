#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: ReferenceData

package ReferenceData;

use strict;

#=========================================================================================

#GetCodonData - notes

#gets codon reference data for the genome for populating a table on the detail web page
#route: summary web page > GetDetail > CalcCodonFreq > GetCodonData > CalcCodonFreq > GetDetail > detail web page

#input: database handle
#output: hash
#hash keys ~ codons, hash values ~ references to arrays
#array values ~ amino acid, genome freq, genome ratio

#-----------------------------------------------------------------------------------------

#GetCodonData - manual test
#use DbiHandle;
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = GetCodonData($dbh);
#foreach my $codon(keys(%codons)) {
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetCodonData($) {
	
	my ($dbh) = @_;	
	$dbh
		or die ("Unable to process request for codon reference data");
	
	my $sql = 
	"SELECT codon, one_letter_id, codon_freq, codon_ratio
	FROM codon";

	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct codon query");
	
	$sth->execute
		or die ("Unable to run codon query");
	
	my %codons;
	while (my @row = $sth->fetchrow_array) {
		push @{$codons{@row[0]}}, @row[1], @row[2], @row[3]; 
	}
	
	if ($sth->rows < 64) {
        print ("Codon reference data incomplete.\n");
    }
	
	return %codons;

	$sth->finish;
	
}

#=========================================================================================

#GetEnzymeData - notes

#gets restriction enzyme reference data for populating a drop down box or radio buttons on the detail web page
#route: summary web page > GetDetail > GetEnzymeData > GetDetail > detail web page

#input: database handle
#output: hash
#hash keys ~ enzyme names, hash values ~ restriction sequences

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
		or die ("Unable to process request for restriction enzyme data");

	my $sql = 
	"SELECT abbreviation, restriction_seq
	FROM restriction_enzyme";
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct restriction enzyme query");

	$sth->execute
		or die ("Unable to run restriction enzyme query");
		
	my %enzymes;
	while (my @row = $sth->fetchrow_array) {
		$enzymes{@row[0]} = @row[1]; 
	}
	
	if (0 == $sth->rows) {
        print ("No restriction enzymes included in reference data.\n");
	}
	
	return %enzymes;
	
	$sth->finish;
	
}

#=========================================================================================

1;
