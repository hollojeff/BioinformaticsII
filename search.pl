#!/usr/bin/perl
use GenBankData;
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

@result = GenBankData::GetSummaryData($form, $search, $return);

print $cgi->header();
print <<__EOF;
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Chromasome 4 Analysis</title>

    <!-- Bootstrap -->
    <link href="http://student.cryst.bbk.ac.uk/~jhurst03/css/bootstrap.min.css" rel="stylesheet">

    <!-- Custom styles for this template -->
    <link href="http://student.cryst.bbk.ac.uk/~jhurst03/css/search-form.css" rel="stylesheet">

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src= "https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  
  <body>
      <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#">Chromasome 4</a>
        </div>
        <div class="collapse navbar-collapse">
          <ul class="nav navbar-nav">
            <li class="active"><a href="#">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
          </ul>
        </div><!--/.nav-collapse -->
      </div>
    </div>
    
  <div class="container">
      <div class="search-form">

 <h1>Chromasome</h1>
    <h2>Results:</h2>
    <form action='/cgi-bin/cgiwrap/jhurst03/detailtest.pl' method='post'>
    <table class="table">
      <tr>
        <th>Gene Identifier</th>
        <th>Protein product names</th>
        <th>Genbank Accession</th>
	 <th>Chromosomal Location</th>
      </tr>
__EOF
   
#for loop to build table
for (my $i=0; $i < scalar @result; $i=$i+4) { 
print <<__EOF;
     <tr>
        <td> $result[$i] </td>
        <td> $result[$i+1] </td>
        <td> $result[$i+2] </td>
	<td> $result[$i+3] </td>
	<td><button type="submit" name="action" value="$result[$i+2]">Details</button></td>
      </tr>
__EOF
}
print <<__EOF
      </div>
    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="js/bootstrap.min.js"></script>
  </body>
</html>
__EOF
}