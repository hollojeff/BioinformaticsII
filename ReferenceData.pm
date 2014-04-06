#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: ReferenceData

package ReferenceData;

use strict;
use DbiHandle;

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output

#my %codons = GetCodonData();

#foreach my $codon(keys(%codons)) {
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetCodonData() {
	
	my $sql = 
	"SELECT codon, one_letter_id, codon_freq, codon_ratio
	FROM codon";

	my $dbh = DbiHandle::GetDbHandle();
	my $sth = $dbh->prepare($sql);
	
	if ($sth->execute) {
#		my $nrows = $sth->dump_results;
		my %codons;
		while (my @row = $sth->fetchrow_array) {
			push @{$codons{@row[0]}}, @row[1], @row[2], @row[3]; 
		}
		return %codons;
	}
	
	else {
		return;
	}	
	
}

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output

#my %enzymes = GetEnzymeData();

#foreach my $enzyme(keys(%enzymes)) {
#	print $enzyme, ", ", $enzymes{$enzyme}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetEnzymeData() {

	my $sql = 
	"SELECT abbreviation, restriction_seq
	FROM restriction_enzyme";
	
	my $dbh = DbiHandle::GetDbHandle();
	my $sth = $dbh->prepare($sql);

	if ($sth->execute) {
#		my $nrows = $sth->dump_results;
		my %enzymes;
		while (my @row = $sth->fetchrow_array) {
			$enzymes{@row[0]} = @row[1]; 
		}
		return %enzymes;
	}
	
	else {
		return;
	}	
	
}

1;
