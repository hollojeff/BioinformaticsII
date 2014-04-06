#!/usr/bin/perl
#Name: Ginny Devonshire
#Module: DbiHandle

package DbiHandle;

use strict;
use DBI;

sub GetDbHandle{

	my %config;

	open(IN, "DbiConfig.cnf");

	while (my $line = <IN>) {
		if ($line =~ /(\S+)=(\S+)/) {
			$config{$1} = $2;
		}
	}
	
	close(IN);	
	
	my $dbsource = "dbi:mysql:database=$config{dbname};host=$config{dbhost}";
	my $dbh = DBI->connect($dbsource, $config{username}, $config{password});
	
	return $dbh;

}

1;
