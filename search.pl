#!/usr/bin/perl
use CGI;
use strict;
my $cgi = new CGI;
my $form = $cgi->param('form');
my $search = $cgi->param('searchtype');
my $return = $cgi->param('ReturnAll');

if ($return == "Show All"){
	$return = "T";
	}
	else {
	$return ="F";
}

#Clicked on Show all button
#Return all results
if ($return == "T"){

#Call script to return all results

my @return = GenBankData::GetSummaryData($search, $form, $return);

print $cgi->header();
print <<__EOF;
<html>
<head>
 <h1>Chromasome</h1>
    <h2>Results:</h2>
    <table>
    <table border="1" style="width:300px">
      <tr>
        <th>Gene Identifier</th>
        <th>Protein product names</th>
        <th>Genbank Accession</th>
	<th>Chromosomal Location</th>
      </tr>
__EOF
   
#for loop to build table
for (my $i=0; $i < @return; $i=$i+4) { 
print <<__EOF;
     <tr>
        <td> @return[i] </td>
        <td> @return[i+1] </td>
        <td> @return[i+2] </td>
		<td> @return[i+3] </td>
      </tr>
__EOF
}
print <<__EOF
</body>
</html>
__EOF

#Search using form and searchtype
else {

#Call script, sending over searchtype and form for SQL query

my @return = GenBankData::GetSummaryData($search, $form, $return);

print $cgi->header();
print <<__BLAH;
<html>
<head>
   <title>Sequence Analysis Results</title>
</head>
<body>
 <h1>Chromasome</h1>
    <h2>Results:</h2>
    <table>
    <table border="1" style="width:300px">
      <tr>
        <th>Gene Identifier</th>
        <th>Protein product names</th>
        <th>Genbank Accession</th>
	<th>Chromosomal Location</th>
      </tr>
__EOF
   
#for loop to build table
for (my $i=0; $i < @return; $i=$i+4) { 
print <<__EOF;
     <tr>
        <td> @return[i] </td>
        <td> @return[i+1] </td>
        <td> @return[i+2] </td>
		<td> @return[i+3] </td>
      </tr>
__EOF
}
print <<__EOF
</body>
</html>
__EOF

}
