#!/usr/bin/perl
#Name: Ginny Devonshire
#Middle layer module: GenBankData
#Includes: sub-routines to get and/or manipulate genbank data

package GenBankData;

use strict;
use DbiHandle;

#=========================================================================================

#GetSummaryData - notes

#gets gene data for genes that match the user's search criteria
#output used for display on the summary web page
#search page >> GetSummaryData >> summary page

#inputs: filter field, filter value, show all true/false flag
#output: array1
#array1 values ~ references to arrays2
#array2 values ~ accession no, location, gene id, product

#-----------------------------------------------------------------------------------------

#GetSummaryData - manual test
#my @summary = GetSummaryData('genbank', 'EF1%', "F");
#foreach my $row(@summary) {
#	print @{$row}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetSummaryData($$$) {

	my ($filter, $value, $showAll) = @_;

	#create a query to return all the gene records	
	my $sql = 
	"SELECT accession, location, gene_id, product
	FROM dna_sequence";	
	
	#if the user hasn't opted to show all the gene records	
	if ($showAll ne "T") {	
	
		#if search criteria are specified
		if ($filter && $value) {	
		
			#translate the filter field from the web name to the sql name 
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
			#if the filter field isn't valid, ignore the filter and switch the show all flag to true
			else {
				print ("Search criterion not valid, filter: " . $filter . "\n");
				$showAll = "T";
			}
			
			if ($showAll ne "T") {
			
				#construct the sql where clause and append to the sql query
				my $sqlOperator = "=";
				if ($value =~ /^%.*/ || $value =~ /.*%$/) {
					$sqlOperator = "LIKE";
				}
				$sql = $sql." WHERE ".$filter." ".$sqlOperator." ?";
			
			}
			
		}
		
		#if search criteria aren't specified, switch the show all flag to true
		else {
			print ("Search criteria not fully specified, filter: " . $filter . ", value: " . $value . "\n");
			$showAll = "T";
		}
		
	}

	#run the query
	my $dbh = DbiHandle::GetDbHandle();
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct summary query");
	
	if ($showAll ne "T") {
		$sth->bind_param(1, $value);
	}

	$sth->execute
		or die ("Unable to run summary query");
	
	#create an array for each record, append a reference to each array to the return array
	my @summary;
	while (my @row = $sth->fetchrow_array) {
		push @summary, \@row; 
	}
	
	if (0 == $sth->rows) {
        print ("No gene records found for these search criteria, filter: " . $filter . ", value: " . $value . "\n");
    }
	
	$sth->finish;
	$dbh->disconnect();
	
	return @summary;	

}

#=========================================================================================

#GetGeneData - notes

#gets gene data for a gene selected by the user
#output used for display on the detail web page and to provide parameters for other sub-routines called from GetDetail
#summary page >> GetDetail >> GetGeneData >> GetDetail >> detail page

#output also used to provide the dna sequence for finding restriction sites
#detail page >> FindRestrictionSites >> GetGeneData >> FindRestrictionSites >> restriction page

#inputs: accession number, database handle
#output: array
#array values ~ accession no, location, gene id, product, dna sequence, coding sequence, product sequence, dna sequence length, complement flag

#-----------------------------------------------------------------------------------------

#GetGeneData - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my @gene = GetGeneData('CD123456', $dbh);
#print @gene, "\n";

#-----------------------------------------------------------------------------------------

sub GetGeneData($$) {

	my ($accessionNo, $dbh) = @_;
	$accessionNo && $dbh
		or die ("Unable to process request for gene data");

	#create and run a query to return the gene record	
	my $sql = 
	"SELECT accession, location, gene_id, product, dna_seq, coding_seq, aminoAcid_seq, seq_length, comp_flag 
	FROM dna_sequence 
	WHERE accession = ?";

	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct gene query");
	
	$sth->bind_param(1, $accessionNo);
	
	$sth->execute
		or die ("Unable to run gene query");
	
	#create an array of the record values
	my @gene = $sth->fetchrow_array;
	
	if (0 == $sth->rows) {
        print ("No gene records found for this accession number: " . $accessionNo . "\n");
    }

	$sth->finish;
	
	#if the dna sequence length isn't available in the database, calculate 
	if (@gene[7] == "" || @gene[7] == 0) {
		@gene[7] = length(@gene[4])
	}

	#if the gene is on the complementary strand, convert the dna and coding sequences 
	if (@gene[8] eq "Y") {
		@gene[4] = ReverseComplementSequence(@gene[4]);
		@gene[5] = ReverseComplementSequence(@gene[5]);
	}
	elsif (@gene[8] ne "N") {
		@gene[8] = "N"
	}

	return @gene;

}

#=========================================================================================

#GetExonData - notes

#gets exon data for a gene selected by the user
#output used for highlighting the exons on the dna sequence on the detail web page
#summary page >> GetDetail >> GetExonData >> GetDetail >> detail page

#output also used to identify the up and downstream region boundaries
#detail page >> FindRestrictionSites >> GetExonData >> FindRestrictionSites >> restriction page

#inputs: accession number, complement flag, dna sequence length, database handle
#output: hash
#hash keys ~ exon start positions, hash values ~ exon end positions

#-----------------------------------------------------------------------------------------

#GetExonData - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my %exons = GetExonData('CD123456', 'N', '10', $dbh);
#foreach my $exon(keys(%exons)) {
#	print $exon, ", ", $exons{$exon}, "\n";
#}

#-----------------------------------------------------------------------------------------

sub GetExonData($$$$) {

	my ($accessionNo, $complementFlag, $seqLength, $dbh, ) = @_;
	$accessionNo && $complementFlag && $seqLength && $dbh
		or die ("Unable to process request for exon data");
	
	#create and run a query to return the exon records
	my $sql = 
	"SELECT start_pos, end_pos
	FROM coding_sequence_positions
	WHERE accession = ?";
	
	my $sth = $dbh->prepare($sql)
		or die ("Unable to construct exon query");
	
	$sth->bind_param(1, $accessionNo);

	$sth->execute
		or die ("Unable to run exon query");

	my %exons;
	
	#if the gene is on the complementary strand  
	if ($complementFlag eq "Y") {
		
		#convert the start and end positions and append each record to the return hash
		while (my @row = $sth->fetchrow_array) {
			$exons{$seqLength - @row[1] + 1} = $seqLength - @row[0] + 1;
		}
		
	}
	
	else {
	
		#just append each record to the return hash
		while (my @row = $sth->fetchrow_array) {
			$exons{@row[0]} = @row[1];
		}	
		
	}
	
	if (0 == $sth->rows) {
        print ("No exon records found for this accession number: " . $accessionNo . "\n");
    }

	$sth->finish;

	return %exons;

}

#=========================================================================================

#ReverseComplementSequence - notes

#generates the sequence of the complementary dna strand and reverses it
#output used for display of the dna sequence and coding sequence with the 5' to 3' direction reading from left to right,
#and to enable use of standard sub-routines for calculation of codon frequencies and locating restriction sites

#summary page >> GetDetail >> GetGeneData >> ReverseComplementSequence >> GetGeneData >> GetDetail >> detail page
#detail page >> FindRestrictionSites >> GetGeneData >> ReverseComplementSequence >> GetGeneData >> FindRestrictionSites >> restriction page

#input: sequence
#output: reversed complementary sequence

#-----------------------------------------------------------------------------------------

#ReverseComplementSequence - manual test
#my $seq = "AAAAAAGGGGGGCCCCCCTTTTTTAAAAAATTTTT";
#print scalar(reverse($seq)), "\n";
#print ReverseComplementSequence($seq);

#-----------------------------------------------------------------------------------------

sub ReverseComplementSequence($) {

	my ($sequence) = @_;	
	$sequence
		or die ("Unable to process request to complement and reverse sequence");
	
	my %baseComplements = (A => "T", C => "G", G => "C", T => "A");

	$sequence =~ s/([ACGT])/$baseComplements{$1}/g;
	
	$sequence = scalar(reverse($sequence));
	
	return $sequence;
	
}

#=========================================================================================

1;
