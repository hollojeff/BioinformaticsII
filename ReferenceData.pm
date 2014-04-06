#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: ReferenceData

package ReferenceData;

use strict;

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#use DbiHandle;
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = GetCodonData($dbh);
#foreach my $codon(keys(%codons)) {
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetCodonData($) {
	
	my ($dbh) = @_;
	
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
        print ("Codon reference set incomplete.");
    }
	
	return %codons;

	$sth->finish;
	
}

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#use DbiHandle;
#my $dbh = DbiHandle::GetDbHandle();
#my %enzymes = GetEnzymeData($dbh);
#foreach my $enzyme(keys(%enzymes)) {
#	print $enzyme, ", ", $enzymes{$enzyme}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetEnzymeData($) {

	my ($dbh) = @_;

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
        print ("No restriction enzymes included in reference set.");
    }

	return %enzymes;
	
	$sth->finish;
	
}

#=========================================================================================

1;
