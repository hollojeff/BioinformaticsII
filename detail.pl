#!/usr/bin/perl
use CGI;
use strict;
my $cgi = new CGI;
my $form = $cgi->param('form');

#call module to get database details

print $cgi->header();
print <<__EOF;
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chromasome 4 Analysis</title>

    <!-- Bootstrap -->
    <link href="css/bootstrap.min.css" rel="stylesheet">

    <!-- Custom styles for this template -->
    <link href="search-form.css" rel="stylesheet">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src= "https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  
__EOF

 
#Show amino acid sequence

my @codseq = unpack("(A50)*", $codingsequence);
my @amiseq = unpack("(A50)*", $aminosequence);

for (my i=0, i<length(@amiseq), i++){
print @amiseq[i];
}

for (my i=0, i<length(@codseq), i++){
print @codseq[i];
}

#Show codon usage frequency

for (my $i = 0, $i < 16*16, $i=$i+16){
print <<__EOF
<tr>
    <td> @codon[i] </td> <td> @codon[i+1] </td> <td> @codon[i+2] </td> <td> @codon[i+3] </td>
	<td> @codon[i+4] </td> <td> @codon[i+5] </td> <td> @codon[i+6] </td> <td> @codon[i+7] </td>
	<td> @codon[i+9] </td> <td> @codon[i+9] </td> <td> @codon[i+10] </td> <td> @codon[i+11] </td>
	<td> @codon[i+13] </td> <td> @codon[i+13] </td> <td> @codon[i+14] </td> <td> @codon[i+15] </td>
		</tr>
__EOF
}  

#Show complete DNA sequence

my @cstart = keys %exon;
my @cfinish = values %exon;
my $ccount = 0;

for (my $sequence=0, $sequence < length($string), $sequence++){
	for (my $para=0, $para < 50, $para++){
		my $base = substr($string, $sequence, 1);
		if ($base == @cstart[$ccount]){
			print "<span style="background-color: #FFFF00">";
			}
		if ($base == @cfinish[$ccount]){
			print "</span>";
			$ccount++;
			}
		print $base;
		}
	print "<p>";
	}
}


#menu for choosing restriction enzyme sites
print <<__EOF;

#use bootstrap to create a menu for selecting 


