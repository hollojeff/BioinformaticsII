#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: GenBankAnalysis

package GenBankAnalysis;

use strict;
use DbiHandle;
use GenBankData;
use ReferenceData;

#=========================================================================================

#GetDetail - notes

#collates gene, exon, codon, and enzyme data for a specific gene for displaying on the detail web page
#routes: summary web page > GetDetail	> GetGeneData			> GetDetail > detail web page
#					> GetExonData			>
#					> CalcCodonFreq > GetCodonData	>
#					> GetEnzymeData			>

#input: gene id
#outputs: references to gene detail array, exon hash, codon hash, enzyme hash
#gene detail array values ~ accession no, location, gene id,  product, DNA sequence, coding sequence, product sequence
#exon hash keys ~ exon start positions, exon hash values ~ exon end positions
#codon hash keys ~ codons, codon hash values ~ references to codon arrays
#codon array values ~ amino acid, genome freq, genome ratio, gene freq, gene ratio
#enzyme hash keys ~ enzyme names, enzyme hash values ~ restriction sequences

#-----------------------------------------------------------------------------------------

#GetDetail - manual test
#my @detail = GetDetail('ABC1');
#my @gene = @{@detail[0]};
#my %exons = %{@detail[1]};
#my %codons = %{@detail[2]};
#my %enzymes = %{@detail[3]};
#print @gene, "\n";
#foreach my $exon(keys(%exons)) {
#	print $exon, ", ", $exons{$exon}, "\n";
#}	
#foreach my $codon(keys(%codons)) {
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	
#foreach my $enzyme(keys(%enzymes)) {
#	print $enzyme, ", ", $enzymes{$enzyme}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetDetail($) {

	my ($gene) = @_;
	$gene
		or die ("Unable to process request for detailed gene data");

	my $dbh = DbiHandle::GetDbHandle();

	my @gene = GenBankData::GetGeneData($gene, $dbh);
	my %exons = GenBankData::GetExonData($gene, $dbh);
	
	my $codingSeq = @gene[5];
	my %codons = CalcCodonFreq($codingSeq, $dbh);
	
	my %enzymes = ReferenceData::GetEnzymeData($dbh);
	
	return \@gene, \%exons, \%codons, \%enzymes;
	
	$dbh->disconnect();
}

#=========================================================================================

#CalcCodonFreq - notes

#calculates codon frequencies and ratios for a specific gene for populating a table on the detail web page
#route: summary web page > GetDetail > CalcCodonFreq > GetCodonData > CalcCodonFreq > GetDetail > detail web page

#input: coding sequence, database handle
#output: hash
#hash keys ~ codons, hash values ~ references to arrays
#array values ~ amino acid, genome freq, genome ratio, gene freq, gene ratio

#-----------------------------------------------------------------------------------------

#CalcCodonFreq - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = CalcCodonFreq('', $dbh);
#foreach my $codon(keys(%codons)){
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub CalcCodonFreq($$) {

	my ($codingSeq, $dbh) = @_;
	$codingSeq && $dbh
		or die ("Unable to process request for codon frequency data");
	
	my %codonsU = ReferenceData::GetCodonData($dbh);
	my %codons;
	
	foreach my $codonU(keys(%codonsU)) {
		my $codon = $codonU;		
		$codon =~ s/U/T/g;
		$codons{$codon} = $codonsU{$codonU};
	}
	
	my %codonCounts;
	my %acidCounts;
	my $totalCount;

	while ($codingSeq =~ /(.{3})/g) {	#wildcard used to maintain triplet positions if seq includes non-bases
	
		$codonCounts{$1}++;
		
		my %codonsCopy = %codons;	#copy used so non-codons are not added to hash if seq includes non-codons
		my $acid = @{$codonsCopy{$1}}[0]; 
		$acidCounts{$acid}++;
		
		$totalCount++;
		
	}
	
	foreach my $codon(keys(%codons)) {
		
		my $codonFreq = 0;
		my $codonRatio = 0;
		
		if (1 == exists($codonCounts{$codon})) {
						
			$codonFreq = $codonCounts{$codon}*1000/$totalCount;
				
			my $acid = @{$codons{$codon}}[0];
			$codonRatio = $codonCounts{$codon}/$acidCounts{$acid};

		}

		push @{$codons{$codon}}, sprintf ("%.1f", $codonFreq), sprintf ("%.2f", $codonRatio);
		
	}	
	
	return %codons;

}

#=========================================================================================

#FindRestrictionSites - notes

#finds restriction sites for a specific gene and a specific enzyme for highlighting on the restriction page
#flags whether restriction sites appear just in up/downstream regions or not
#routes: detail web page > FindRestrictionSites > GetGeneData > FindRestrictionSites > restriction web page
#						> GetExonData >

#inputs: gene id, restriction sequence
#outputs: hash reference, up/downstream only flag
#hash keys ~ restriction site start positions, hash values ~ restriction site end posiions
#first position = 1
#flag values ~ T, true, F, False, U, unknown, N, no sites


#-----------------------------------------------------------------------------------------

#FindRestrictionSites - manual test
#my @results = FindRestrictionSites('ABC1','GAT');
#my %matches = %{@results[0]};
#my $upDownStreamOnly = @results[1];
#foreach my $match(keys(%matches)) {
#	print $match, ", ", $matches{$match}, "\n";
#}
#print $upDownStreamOnly, "\n";

#-----------------------------------------------------------------------------------------

sub FindRestrictionSites($$) {

	my ($gene, $siteSeq) = @_;	
	$gene && $siteSeq
		or die ("Unable to process request for restriction site data");

	my $dbh = DbiHandle::GetDbHandle();
	my @gene = GenBankData::GetGeneData($gene, $dbh);
	
	my %matches;	
	#initialise restriction site flag, set to no restriction sites
	my $upDownStreamOnly = "N";

	if (@gene) {

		my $dnaSeq = @gene[4];
		
		if ($dnaSeq) { 
			
			my $siteSeqLen = length($siteSeq);
	
			while($dnaSeq =~ /$siteSeq/g){
				$matches{pos($dnaSeq)-$siteSeqLen+1} = pos($dnaSeq);
			}
			
			if (%matches) {
			
				my %exons = GenBankData::GetExonData($gene, $dbh);
						
				if (%exons) {
				
					my @exonStartAsc = sort({$a<=>$b} keys(%exons));
					my $codingStart = @exonStartAsc[0];
					my @exonEndDesc = sort({$b<=>$a} values(%exons));
					my $codingEnd = @exonEndDesc[0];
					
					foreach my $match(keys(%matches)) {
					
						#if find a restriction site between up and downstream regions, set flag to false
						if ($matches{$match} >= $codingStart && $match <= $codingEnd) {
							$upDownStreamOnly = "F";
							last;
						}
					
					}
					
					#if no restriction sites found between up and downstream regions, set flag to true
					if ($upDownStreamOnly eq "N") {
						$upDownStreamOnly = "T";
					}

				}
				
				else {
					#no exon data, set flag to unknown
					$upDownStreamOnly = "U";
				}
				
			}
			
			else {
				print ("No restriction sites found for this enzyme in this gene.\n");
			}
			
		}
		
		else {
			print ("No DNA sequence data found for this gene.\n");
		}

	}	
	
	return \%matches, $upDownStreamOnly;
	
	$dbh->disconnect();
	
}

#=========================================================================================

1;
