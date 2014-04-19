#!/usr/bin/perl
#Name: Ginny Devonshire
#Middle layer module: GenBankAnalysis
#Includes: sub-routines to analyse and/or collate genbank data

package GenBankAnalysis;

use strict;
use DbiHandle;
use GenBankData;
use ReferenceData;

#=========================================================================================

#GetDetail - notes

#collates gene, exon, codon, and enzyme data for a gene selected by the user
#outputs used for display on the detail web page
#summary page >> GetDetail >> detail page

#input: accession number
#outputs: references to gene detail array, exon hash, codon hash, enzyme hash
#gene detail array values ~ accession no, location, gene id,  product, DNA sequence, coding sequence, product sequence, dna sequence length, complement flag
#exon hash keys ~ exon start positions, exon hash values ~ exon end positions
#codon hash keys ~ codons, codon hash values ~ references to codon arrays
#codon array values ~ amino acid, genome freqquency, genome ratio, gene frequency, gene ratio
#enzyme hash keys ~ enzyme names, enzyme hash values ~ restriction sequences

#-----------------------------------------------------------------------------------------

#GetDetail - manual test
#my @detail = GetDetail('CD123456');
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

	my ($accessionNo) = @_;
	$accessionNo
		or die ("Unable to process request for detailed gene data");

	my $dbh = DbiHandle::GetDbHandle();

	my @gene = GenBankData::GetGeneData($accessionNo, $dbh);
	
	my $complementFlag = @gene[8];
	my $seqLength = @gene[7];
		
	my %exons = GenBankData::GetExonData($accessionNo, $complementFlag, $seqLength, $dbh);
	
	my %codons;
	my $codingSeq = @gene[5];
	if ($codingSeq) {
		%codons = CalcCodonFreq($codingSeq, $dbh);
	}
	else {
		print ("No coding sequence found for this accession number: " . $accessionNo . "\n");
	}
	
	my %enzymes = ReferenceData::GetEnzymeData($dbh);
	
	return \@gene, \%exons, \%codons, \%enzymes;
	
	$dbh->disconnect();
}

#=========================================================================================

#CalcCodonFreq - notes

#calculates codon usage frequencies and ratios for a gene selected by the user and appends this to the usage data for the genome
#output used to populate a table on the detail web page
#summary page >> GetDetail >> CalcCodonFreq >> GetDetail >> detail page

#input: coding sequence, database handle
#output: hash
#hash keys ~ codons, hash values ~ references to arrays
#array values ~ amino acid, genome frequency, genome ratio, gene frequency, gene ratio

#-----------------------------------------------------------------------------------------

#CalcCodonFreq - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = CalcCodonFreq('AAGAAG', $dbh);
#foreach my $codon(keys(%codons)){
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub CalcCodonFreq($$) {

	my ($codingSeq, $dbh) = @_;
	$codingSeq && $dbh
		or die ("Unable to process request to calculate codon frequencies");
	
	#get the codon reference data (uracil base used)
	my %codonsU = ReferenceData::GetCodonData($dbh);
	my %codons;
	
	if (%codonsU) {
	
		#create a copy of the reference data translating uracil to thymine
		foreach my $codonU(keys(%codonsU)) {
			my $codon = $codonU;		
			$codon =~ s/U/T/g;
			$codons{$codon} = $codonsU{$codonU};
		}
		
		my %codonCounts;
		my %acidCounts;
		my $totalCount;

		#for each triplet in the sequence
		#(the wildcard is used to maintain triplet positions if the sequence includes any non-bases)
		while ($codingSeq =~ /(.{3})/g) {	
			
			#get the amino acid that the codon codes for
			#(a copy of the codon data is used so that any non-codons included in the sequence are not added to the reference data)
			my %codonsCopy = %codons;	
			my $acid = @{$codonsCopy{$1}}[0]; 
			
			#increment the codon counts for the particular codon, the amino acid, and the sequence
			$codonCounts{$1}++;
			$acidCounts{$acid}++;
			$totalCount++;
			
		}
	
		#for each of the 64 codons
		foreach my $codon(keys(%codons)) {
			
			my $codonFreq;
			my $codonRatio;
			
			#calculate the frequency and ratio of the codon usage for the gene
			if (1 == exists($codonCounts{$codon})) {
							
				$codonFreq = $codonCounts{$codon}*1000/$totalCount;
					
				my $acid = @{$codons{$codon}}[0];
				$codonRatio = $codonCounts{$codon}/$acidCounts{$acid};

			}
			
			else {
				$codonFreq = 0;
				$codonRatio = 0;
			}

			#append the frequency and ratio for the gene to the frequency and ratio for the genome
			push @{$codons{$codon}}, sprintf ("%.1f", $codonFreq), sprintf ("%.2f", $codonRatio);
			
		}

	#if no or limited codon reference data is found, GetCodonData prints a message		

	}
	
	return %codons;

}

#=========================================================================================

#FindRestrictionSites - notes

#finds restriction sites for a gene and an enzyme selected by the user
#flags whether any restriction sites are found, and if so, if they appear just in the up and downstream regions or not
#outputs used for highlighting the sites on the DNA sequence on the restriction page
#detail page >> FindRestrictionSites >> restriction page

#inputs: accession number, restriction sequence
#outputs: hash reference, up/downstream only flag
#hash keys ~ restriction site start positions, hash values ~ restriction site end posiions
#first position = 1
#flag values ~ T, true, F, False, U, unknown, N, no sites

#-----------------------------------------------------------------------------------------

#FindRestrictionSites - manual test
#my @results = FindRestrictionSites('CD123456','ATGTA');
#my %matches = %{@results[0]};
#my $upDownStreamOnly = @results[1];
#foreach my $match(keys(%matches)) {
#	print $match, ", ", $matches{$match}, "\n";
#}
#print $upDownStreamOnly, "\n";

#-----------------------------------------------------------------------------------------

sub FindRestrictionSites($$) {

	my ($accessionNo, $siteSeq) = @_;	
	$accessionNo && $siteSeq
		or die ("Unable to process request for restriction site data");

	my $dbh = DbiHandle::GetDbHandle();
	my @gene = GenBankData::GetGeneData($accessionNo, $dbh);
	
	my %matches;
	
	#initialise a restriction site flag, set to no restriction sites found / no data found
	my $upDownStreamOnly = "N";

	if (@gene) {

		my $dnaSeq = @gene[4];
		
		if ($dnaSeq) {
			
			my $siteSeqLen = length($siteSeq);
			
			#find matches for the restriction site sequence and append to the return hash
			while($dnaSeq =~ /$siteSeq/g){
				$matches{pos($dnaSeq)-$siteSeqLen+1} = pos($dnaSeq);
			}
			
			if (%matches) {
			
				my $complementFlag = @gene[8];
				my $seqLength = @gene[7];
		
				my %exons = GenBankData::GetExonData($accessionNo, $complementFlag, $seqLength, $dbh);
				
				if (%exons) {
				
					#get the boundaries for the up and downstream regions
					my @exonStartAsc = sort({$a<=>$b} keys(%exons));
					my $codingStart = @exonStartAsc[0];
					my @exonEndDesc = sort({$b<=>$a} values(%exons));
					my $codingEnd = @exonEndDesc[0];
					
					#look for restriction sites between the up and downstream regions, 
					#if find one, set the flag to false and stop looking
					foreach my $match(keys(%matches)) {
						if ($matches{$match} >= $codingStart && $match <= $codingEnd) {
							$upDownStreamOnly = "F";
							last;
						}
					}
					
					#if no restriction sites found between the up and downstream regions, set the flag to true
					if ($upDownStreamOnly eq "N") {
						$upDownStreamOnly = "T";
					}

				}
				
				#if no exon data is found for the gene, set the flag to unknown
				else {
					$upDownStreamOnly = "U";
				}
				
				#if no exon records are found, GetExonData prints a message
				
			}
			
			else {
				print ("No restriction sites found for this accession number: " . $accessionNo . ", and restriction sequence: " . $siteSeq . "\n");
			}
			
		}
		
		else {
			print ("No DNA sequence found for this accession number: " . $accessionNo . "\n");
		}
		
	#if no gene records are found, GetGeneData prints a message
	
	}	
	
	$dbh->disconnect();	
	
	return \%matches, $upDownStreamOnly;
	
}

1;
