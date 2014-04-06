#!/usr/bin/perl
use CGI;
use strict;
my $cgi = new CGI;
my $form = $cgi->param('form');
my $search = $cgi->param('searchtype');
my $return = $cgi->param('ReturnAll');



#Clicked on Show all button
#Return all results
if ($return == "Show All"){

#Call script to return all results


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
for (my $i=1; $i < 10; $i++) { 
print <<__EOF;
     <tr>
        <td></td>
        <td></td>
        <td></td>
	<td></td>
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
for (my $i=1; $i < 10; $i++) { 
print <<__EOF;
     <tr>
        <td></td>
        <td></td>
        <td></td>
	<td></td>
      </tr>
__EOF
}
print <<__EOF
</body>
</html>
__EOF

}
