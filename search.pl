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

print <<__BLAH;
print $cgi->header();
<html>
<head>
   <title></title>
</head>
<body>
<h1></h1>
</body>
</html>
__BLAH
}

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
<h1>Sequence Analysis Results</h1>
<p>
<p><h2>Your data was:</h2>
<br />$form</p>

<p>This is a $search search</p>
$return
</body>
</html>
__BLAH
}