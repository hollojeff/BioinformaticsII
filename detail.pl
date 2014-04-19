#!/usr/bin/perl
use CGI;
use strict;
my $cgi = new CGI;
my $form = $cgi->param('form');

print $cgi->header();
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
#Show amino acid sequence
print <<__EOF;

__EOF

#Show codon usage frequency
print <<__EOF;

__EOF

#Show complete DNA sequence
print <<__EOF;

__EOF

#menu for choosing restriction enzyme sites
print <<__EOF;

__EOF