#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: GenBankAnalysis

package GenBankAnalysis;

use strict;
use DbiHandle;
use GenBankData;
use ReferenceData;

#=========================================================================================

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
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

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = CalcCodonFreq('AAAAAGACT', $dbh);
#foreach my $codon(keys(%codons)){
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#-----------------------------------------------------------------------------------------

sub CalcCodonFreq($$) {

	my ($codingSeq, $dbh) = @_;
	
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

#-----------------------------------------------------------------------------------------

#manual test for sub-routine output
#my @results = FindRestrictionSites('ABC2', 'ACT');
#my %matches = %{@results[0]};
#my $upDownStreamOnly = @results[1];
#foreach my $match(keys(%matches)) {
#	print $match, ", ", $matches{$match}, "\n";
#}
#print $upDownStreamOnly, "\n";

#-----------------------------------------------------------------------------------------

sub FindRestrictionSites($$) {

	my ($gene, $siteSeq) = @_;	

	my $dbh = DbiHandle::GetDbHandle();

	my @gene = GenBankData::GetGeneData($gene, $dbh);
	my $dnaSeq = @gene[4];		
	
	my $siteSeqLen = length($siteSeq);
	
	my %exons = GenBankData::GetExonData($gene, $dbh);
	
	my @exonStartAsc = sort({$a<=>$b} keys(%exons));
	my $codingStart = @exonStartAsc[0];
	my @exonEndDesc = sort({$b<=>$a} values(%exons));
	my $codingEnd = @exonEndDesc[0];

	my $upDownStreamOnly = "T";
		
	my %matches;
	
	while($dnaSeq =~ /$siteSeq/g){
	
		$matches{pos($dnaSeq)-$siteSeqLen+1} = pos($dnaSeq);
	
		if ($upDownStreamOnly eq "T") {

			if (pos($dnaSeq) >= $codingStart && pos($dnaSeq)-$siteSeqLen+1 <= $codingEnd) {
				$upDownStreamOnly = "F";
			}

		}

	}
	
	return \%matches, $upDownStreamOnly;
	
	$dbh->disconnect();
	
}

#=========================================================================================

1;
