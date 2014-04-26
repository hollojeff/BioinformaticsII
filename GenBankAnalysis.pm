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
#enzyme hash keys ~ enzyme abbreviations, enzyme hash values ~ references to arrays
#enzyme array values ~ recognition sequence, cutting offset

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
#	print $enzyme, ", ", @{$enzymes{$enzyme}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub GetDetail($) {

	my ($accessionNo) = @_;
	$accessionNo
		or die ("Unable to process request for detailed gene data: accession number not specified");

	my $dbh = DbiHandle::GetDbHandle();

	my @gene = GenBankData::GetGeneData($accessionNo, $dbh);
	
	my %exons;
	my %codons;
	my %enzymes;
	
	if (@gene) {

		unless (@gene[1]) {
			print ("No location found for this accession number: " . $accessionNo . "\n");
		}
		unless (@gene[2]) {
			print ("No gene ID found for this accession number: " . $accessionNo . "\n");
		}
	
		#if the dna sequence is available in the database
		if (@gene[4]) {
	
			my $complementFlag = @gene[8];
			my $seqLength = @gene[7];
		
			%exons = GenBankData::GetExonData($accessionNo, $complementFlag, $seqLength, $dbh);
			#if no exon records are found, GetExonData prints a message
			#subroutine returns empty exon hash	
			
		}
		else {
			print ("No DNA sequence found for this accession number: " . $accessionNo . "\n");
			#subroutine returns empty exon hash	
		}
			
		my $codingSeq = @gene[5];
		if ($codingSeq) {
			%codons = CalcCodonFreq($codingSeq, $dbh);
			#if no reference codon records are found, GetCodonData prints a message
			#subroutine returns empty codon hash
		}
		else {
			print ("No coding sequence found for this accession number: " . $accessionNo . "\n");
			#subroutine returns empty codon hash
		}
		
		unless (@gene[6]) {
			print ("No amino acid sequence found for this accession number: " . $accessionNo . "\n");
		}
		unless (@gene[3]) {
			print ("No product found for this accession number: " . $accessionNo . "\n");
		}
		
		%enzymes = ReferenceData::GetEnzymeData($dbh);
		#if no enzyme records are found, GetEnzymeDate prints a message
		#subroutine returns empty enzyme hash
	
	}
	#if no gene records are found, GetGeneData prints a message
	#subroutine returns empty gene array
	
	$dbh->disconnect();
	
	return \@gene, \%exons, \%codons, \%enzymes;
	
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
	$dbh
		or die ("Unable to process request to calculate codon frequencies: unable to access database");
	$codingSeq
		or die ("Unable to process request to calculate codon frequencies: coding sequence not specified");
	
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
			if (exists($codonCounts{$codon})) {
							
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

	}	
	#if no or limited codon reference data is found, GetCodonData prints a message
	#if no codon reference data is found, subroutine returns empty hash
	
	return %codons;

}

#=========================================================================================

#FindRestrictionSites - notes

#finds restriction enzyme sites for a gene and an enzyme selected or entered by the user
#flags whether any restriction sites are found, and if so, if the enzyme cuts just in the up and downstream regions or not
#outputs used for highlighting the restriction sites on the DNA sequence on the restriction page
#detail page >> FindRestrictionSites >> restriction page

#inputs: accession number, recognition sequence, cutting offset from 5' end of recognition sequence
#0 ~ cuts immediately upstream of sequence, -1 ~ cuts one base upstream of 5' end, +1 ~ cuts one base downstream of 5' end, and so on
#outputs: hash reference, up/downstream only flag
#hash keys ~ recognition sequence start positions, hash values ~ recognition sequence end positions
#flag values ~ T, true, F, False, U, unknown, N, no sites

#-----------------------------------------------------------------------------------------

#FindRestrictionSites - manual test
#my @results = FindRestrictionSites('CD123456','ACTBB', '-1');
#my %matches = %{@results[0]};
#my $upDownStreamOnly = @results[1];
#foreach my $match(keys(%matches)) {
#	print $match, ", ", $matches{$match}, "\n";
#}
#print $upDownStreamOnly, "\n";

#-----------------------------------------------------------------------------------------

sub FindRestrictionSites($$$) {

	my ($accessionNo, $siteSeq, $cutOffset) = @_;	
	$accessionNo && $siteSeq && $cutOffset ne ""
		or die ("Unable to process request for restriction site data for this accession number: " . $accessionNo . ", site sequence: " . $siteSeq . ", and cutting offset: " . $cutOffset);

	my $dbh = DbiHandle::GetDbHandle();
	my @gene = GenBankData::GetGeneData($accessionNo, $dbh);
	
	my %matches;
	
	#initialise a restriction site flag, set to no restriction sites found / no data found
	my $upDownStreamOnly = "N";

	if (@gene) {
	
		#if the dna sequence is available in the database
		if (@gene[4]) {

			my $dnaSeq = @gene[4];
			my $siteSeqLen = length($siteSeq);

			#replace base codes in the recognition sequence with a regex pattern
			my %basePatterns = (N => "[ACGT]", 
			M => "[AC]", R => "[AG]", W => "[AT]", Y => "[CT]", S => "[CG]", K => "[GT]", 
			H => "[ACT]", B => "[CGT]", V => "[ACG]", D => "[AGT]");
			$siteSeq =~ s/([^ACGT])/$basePatterns{$1}/g;
			
			#find matches for the recognition sequence and append to the return hash
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
					
					#look for restriction RECOGNITION sites between the up and downstream regions, 
					#including sites that overlap the up or downstream region,
					#if find one, set the flag to false and stop looking
					#foreach my $match(keys(%matches)) {
					#	if ($matches{$match} >= $codingStart && $match <= $codingEnd) {
					#		$upDownStreamOnly = "F";
					#		last;
					#	}
					#}
					
					#look for restriction CUTTING sites between the up and downstream regions, 
					#excluding cutting sites exactly on the boundaries,
					#if find one, set the flag to false and stop looking
					foreach my $match(keys(%matches)) {
						if ($match + $cutOffset > $codingStart && $match + $cutOffset <= $codingEnd) {
							$upDownStreamOnly = "F";
							last;
						}
					}
					
					#if no sites found between the up and downstream regions, set the flag to true
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
				#subroutine returns empty hash
			}
			
		}
		else {
			print ("No DNA sequence found for this accession number: " . $accessionNo . "\n");
			#subroutine returns empty hash	
		}
	
	}	
	#if no gene records are found, GetGeneData prints a message
	#subroutine returns empty hash
	
	$dbh->disconnect();	
	
	return \%matches, $upDownStreamOnly;
	
}

1;
