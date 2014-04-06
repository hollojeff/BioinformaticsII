#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: GenBankData

package GenBankData;

use strict;
use DbiHandle;

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output

#my @summary = GetSummaryData("genbank","AB123%","F");

#foreach my $row(@summary) {
#	print @{$row}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetSummaryData($$$) {

	my $sql = 
	"SELECT dna_sequence.accession, location, gene_id, product
	FROM dna_sequence
	INNER JOIN gene ON dna_sequence.accession = gene.accession";	
	
	my $value = $_[1];		
	my $showAll = $_[2];
		
	if ($showAll eq "F") {	
	
		my $filter = $_[0];
	
		if ($filter eq "" || $value eq "") {
			return;
		}
		
		else {	
		
			if ($filter eq "genbank") {
				$filter = "dna_sequence.accession";
			}
			elsif ($filter eq "chrloc") {
				$filter = "location";
			}
			elsif ($filter eq "geneid") {
				$filter = "gene.gene_id";
			}
			elsif ($filter eq "product") {
				$filter = "product";
			}
			else {
				return;
			}
			
			my $sqlOperator = "=";
			if ($value =~ /^%.*/ || $value =~ /.*%$/) {
				$sqlOperator = "LIKE";
			}
			
			$sql = $sql." WHERE ".$filter." ".$sqlOperator." ?";
			
		}
		
	}

	my $dbh = DbiHandle::GetDbHandle();
	my $sth = $dbh->prepare($sql);
	
	if ($showAll eq "F") {
		$sth->bind_param(1, $value);
	}

	if ($sth->execute) {
		#my $nrows = $sth->dump_results;
		my @summary;
		while (my @row = $sth->fetchrow_array) {
			push @summary, \@row; 
		}
		return @summary;	
	}
	
	else {
		return;
	}	
	
}

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output

#my @gene = GetGeneData('ABC');

#print @gene, "\n";

#-----------------------------------------------------------------------------------------

sub GetGeneData($) {

	my $sql = 
	"SELECT dna_sequence.accession, location, gene_id, product, dna_seq, coding_seq, aminoAcid_seq 
	FROM dna_sequence 
	INNER JOIN gene ON dna_sequence.accession = gene.accession 
	WHERE gene.gene_id = ?";

	my $dbh = DbiHandle::GetDbHandle();
	my $sth = $dbh->prepare($sql);
	
	my $gene = @_[0];
	$sth->bind_param(1, $gene);
	
	if ($sth->execute) {
#		my $nrows = $sth->dump_results;
		my @gene = $sth->fetchrow_array;
		return @gene;
	}
	
	else {
		return;
	}
	
}

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output

#my %exons = GetExonData('ABC');

#foreach my $exon(keys(%exons)) {
#	print $exon, ", ", $exons{$exon}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetExonData($) {

	my $sql = 
	"SELECT start_pos, end_pos
	FROM code_sequence_positions
	WHERE gene_id = ?";
	
	my $dbh = DbiHandle::GetDbHandle(); 
	my $sth = $dbh->prepare($sql);
	
	my $gene = @_[0];
	$sth->bind_param(1, $gene);

	if ($sth->execute) {
#		my $nrows = $sth->dump_results;
		my %exons;
		while (my @row = $sth->fetchrow_array) {
			$exons{@row[0]} = @row[1]; 
		}
		return %exons;
	}
	
	else {
		return;
	}	
	
}

1;
