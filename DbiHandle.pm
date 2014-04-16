#!/usr/bin/perl
#Name: Ginny Devonshire
#Middle layer module: DbiHandle

package DbiHandle;

use strict;
use DBI;

#=========================================================================================

#GetDbHandle - notes

#reads details from a configuration file and provides a database handle for other subroutines

#input: none
#output: database handle

#called from: GetSummaryData, GetDetailData, FindRestrictionSites
#database handle passed to other subroutines from these three

#-----------------------------------------------------------------------------------------

sub GetDbHandle() {

	my $file = "DbiConfig.cnf";
	open(IN, $file)
		or die ("Unable to open configuration file for Chromosome 4 database: " . $file);

	my %config;	
	while (my $line = <IN>) {
		if ($line =~ /(\S+)=(\S+)/) {
			$config{$1} = $2;
		}
	}
	
	close(IN);	
	
	my $dbsource = "dbi:mysql:database=$config{dbname};host=$config{dbhost}";
	my $dbh = DBI->connect($dbsource, $config{username}, $config{password}, {PrintError => 0}) 
		or die ("Unable to connect to Chromosome 4 database: " . DBI::errstr);
	
	return $dbh;

}

#=========================================================================================

1;
