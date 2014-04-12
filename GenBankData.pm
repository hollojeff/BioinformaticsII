#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: GenBankData

package GenBankData;

use strict;
use DbiHandle;

#=========================================================================================

#GetSummaryData - notes

#gets gene data for genes that match search criteria for displaying on the summary web page
#route: search web page > GetSummaryData > summary web page

#inputs: filter field, filter value, show all true/false flag
#output: array1
#array1 values ~ references to arrays2
#array2 values ~ accession no, location, gene id, product

#-----------------------------------------------------------------------------------------

#GetSummaryData - manual test
#my @summary = GetSummaryData('genbank', 'AB1%', "F");
#foreach my $row(@summary) {
#	print @{$row}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetSummaryData($$$) {

	my ($filter, $value, $showAll) = @_;

	my $sql = 
	"SELECT accession, location, gene_id, product
	FROM dna_sequence";	
		
	if ($showAll ne "T") {	
	
		if ($filter && $value) {	
		
			if ($filter eq "genbank") {
				$filter = "accession";
			}
			elsif ($filter eq "chrloc") {
				$filter = "location";
			}
			elsif ($filter eq "geneid") {
				$filter = "gene_id";
			}
			elsif ($filter eq "product") {
				$filter = "product";
			}
			else {
				print ("Search criteria not valid.");
				$showAll = "T";
			}
			
			if ($showAll ne "T") {
			
				my $sqlOperator = "=";
				if ($value =~ /^%.*/ || $value =~ /.*%$/) {
					$sqlOperator = "LIKE";
				}
			
				$sql = $sql." WHERE ".$filter." ".$sqlOperator." ?";
			
			}
			
		}
		
		else {
			print ("Search criteria not fully specified.");
			$showAll = "T";
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
        print ("No data found for these search criteria.\n");
    }
	
	return @summary;	
	
	$sth->finish;
	$dbh->disconnect();
	
}

#=========================================================================================

#GetGeneData - notes

#gets gene data for a specific gene for displaying on the detail web page
#route: summary web page > GetDetail > GetGeneData > GetDetail > detail web page

#also gets gene data for a specific gene for finding restriction sites
#route: detail web page > FindRestrictionSites > GetGeneData > FindRestrictionSites > restriction web page

#inputs: accession number, database handle
#output: array
#array values ~ accession no, location, gene id,  product, DNA sequence, coding sequence, product sequence

#-----------------------------------------------------------------------------------------

#GetGeneData - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my @gene = GetGeneData('AB123456', $dbh);
#print @gene, "\n";

#-----------------------------------------------------------------------------------------

sub GetGeneData($$) {

	my ($accessionNo, $dbh) = @_;
	$accessionNo && $dbh
		or die ("Unable to process request for gene data");

	my $sql = 
	"SELECT accession, location, gene_id, product, dna_seq, coding_seq, aminoAcid_seq 
	FROM dna_sequence 
	WHERE accession = ?";

	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct gene query");
	
	$sth->bind_param(1, $accessionNo);
	
	$sth->execute
		or die ("Unable to run gene query");
	
	my @gene = $sth->fetchrow_array;
	
	if (0 == $sth->rows) {
        print ("No data found for this gene.\n");
    }

	return @gene;
	
	$sth->finish;
	
}

#=========================================================================================

#GetExonData - notes

#gets exon data for a specific gene for highlighting against the DNA sequence on the detail web page
#route: summary web page > GetDetail > GetExonData > GetDetail > detail web page

#also gets exon data for a specific gene for comparing with restriction site data
#route: detail web page > FindRestrictionSites > GetExonData > FindRestrictionSites > restriction web page

#inputs: accession number, database handle
#output: hash
#hash keys ~ exon start positions, hash values ~ exon end positions

#-----------------------------------------------------------------------------------------

#GetExonData - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my %exons = GetExonData('CD123456', $dbh);
#foreach my $exon(keys(%exons)) {
#	print $exon, ", ", $exons{$exon}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetExonData($$) {

	my ($accessionNo, $dbh) = @_;
	$accessionNo && $dbh
		or die ("Unable to process request for exon data");
		
	my $sql = 
	"SELECT start_pos, end_pos
	FROM code_sequence_positions
	WHERE accession = ?";
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct exon query");
	
	$sth->bind_param(1, $accessionNo);

	$sth->execute
		or die ("Unable to run exon query");
	
	my %exons;
	while (my @row = $sth->fetchrow_array) {
		$exons{@row[0]} = @row[1]; 
	}
	
	if (0 == $sth->rows) {
        print ("No exon data found for this gene.\n");
    }
	
	return %exons;

	$sth->finish;
	
}

#=========================================================================================

1;
