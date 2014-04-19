#!/usr/bin/perl
#Name: Ginny Devonshire
#Database layer script: UpdateReferenceData.pl

use strict;
use DbiHandle;
use ReferenceData;

#=========================================================================================

#UpdateReferenceData - notes

#calculates the ratio of codon usage to acid usage for the genome and updates the codon usage reference data

#-----------------------------------------------------------------------------------------

my $dbh = DbiHandle::GetDbHandle();

#get the codon reference data
my %codons = ReferenceData::GetCodonData($dbh);

if (%codons) {

	my %acidFreqs;
	
	#for each of the 64 codons
	foreach my $codon(keys(%codons)) {
		
		#add the frequency of the codon usage to the frequency of its acid usage
		my $acid = @{$codons{$codon}}[0];	
		my $codonFreq = @{$codons{$codon}}[1];
		$acidFreqs{$acid} += $codonFreq;
		
	}
	print "\n";
	
	#for each of the 64 codons
	foreach my $codon(keys(%codons)) {
		
		my $acid = @{$codons{$codon}}[0];
		my $codonRatio;
		
		#calculate the ratio of the codon usage to its acid usage
		if ($acidFreqs{$acid} != 0) {
			my $codonFreq = @{$codons{$codon}}[1];		
			$codonRatio = $codonFreq/$acidFreqs{$acid};
		}
		else {
			$codonRatio = 0;
		}
		
		$codonRatio = sprintf ("%.2f", $codonRatio);
		
		#create a query to update the codon record
		my $sql = 
		"UPDATE codon
		SET codon_ratio = ?
		WHERE codon = ?";

		my $sth = $dbh->prepare($sql)
			or die ("Unable to construct codon update");
			
		$sth->bind_param(1, $codonRatio);
		$sth->bind_param(2, $codon);

		$sth->execute
			or die ("Unable to run codon update");
			
		$sth->finish;

	}

$dbh->disconnect();	
	
#if no or limited codon reference data is found, GetCodonData prints a message	
	
}

#-----------------------------------------------------------------------------------------

#UpdateReferenceData - manual test
#my $dbh = DbiHandle::GetDbHandle();
#my %codons = ReferenceData::GetCodonData($dbh);
#foreach my $codon(keys(%codons)){
#	print $codon, ", ", @{$codons{$codon}}, "\n";
#}	

#=========================================================================================

