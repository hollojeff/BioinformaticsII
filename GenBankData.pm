#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: GenBankData

package GenBankData;

use strict;
use DbiHandle;

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#my @summary = GetSummaryData("genbank", "");
#foreach my $row(@summary) {
#	print @{$row}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetSummaryData($$$) {

	my ($filter, $value, $showAll) = @_;

	my $sql = 
	"SELECT dna_sequence.accession, location, gene_id, product
	FROM dna_sequence
	INNER JOIN gene ON dna_sequence.accession = gene.accession";	
		
	if ($showAll ne "T") {	
	
		if ($filter eq "" || $value eq "") {
			print ("Search criteria not specified.");
			$showAll = "T";
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
				print ("Search criteria not valid.");
				$showAll = "T";
			}
			
			my $sqlOperator = "=";
			if ($value =~ /^%.*/ || $value =~ /.*%$/) {
				$sqlOperator = "LIKE";
			}
			
			$sql = $sql." WHERE ".$filter." ".$sqlOperator." ?";
			
		}
		
	}

	my $dbh = DbiHandle::GetDbHandle();
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct summary query");
	
	if ($showAll ne "T") {
		$sth->bind_param(1, $value);
	}

	$sth->execute
		or die ("Unable to run summary query");
		
	my @summary;
	while (my @row = $sth->fetchrow_array) {
		push @summary, \@row; 
	}
	
	if (0 == $sth->rows) {
        print ("No data found matching search criteria.");
    }
	
	return @summary;	
	
	$sth->finish;
	$dbh->disconnect();
	
}

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#my $dbh = DbiHandle::GetDbHandle();
#my @gene = GetGeneData('ABC', $dbh);
#print @gene, "\n";

#-----------------------------------------------------------------------------------------

sub GetGeneData($$) {

	my ($gene, $dbh) = @_;

	my $sql = 
	"SELECT dna_sequence.accession, location, gene_id, product, dna_seq, coding_seq, aminoAcid_seq 
	FROM dna_sequence 
	INNER JOIN gene ON dna_sequence.accession = gene.accession 
	WHERE gene.gene_id = ?";

	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct gene query");
	
	$sth->bind_param(1, $gene);
	
	$sth->execute
		or die ("Unable to run gene query");
	
	my @gene = $sth->fetchrow_array;
	
	if (0 == $sth->rows) {
        print ("No data found for this gene.");
    }

	return @gene;
	
	$sth->finish;
	
}

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#my $dbh = DbiHandle::GetDbHandle();
#my %exons = GetExonData('ABC3', $dbh);
#foreach my $exon(keys(%exons)) {
#	print $exon, ", ", $exons{$exon}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetExonData($$) {

	my ($gene, $dbh) = @_;

	my $sql = 
	"SELECT start_pos, end_pos
	FROM code_sequence_positions
	WHERE gene_id = ?";
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct exon query");
	
	$sth->bind_param(1, $gene);

	$sth->execute
		or die ("Unable to run exon query");
	
	my %exons;
	while (my @row = $sth->fetchrow_array) {
		$exons{@row[0]} = @row[1]; 
	}
	
	if (0 == $sth->rows) {
        print ("No exon data found for this gene.");
    }
	
	return %exons;

	$sth->finish;
	
}

#=========================================================================================

1;
