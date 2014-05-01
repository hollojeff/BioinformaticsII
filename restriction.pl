#!/usr/bin/perl
use GenBankAnalysis;
use CGI;
use strict;
my $cgi = new CGI;
my $accno = $cgi->param("submit");
my $enzyme = $cgi->param("enzyme");
my $defseq = $cgi->param("form");

my @detail = GenBankAnalysis::GetDetail($accno);
my @gene = @{@detail[0]};
my %enzymes = %{@detail[3]};


print $cgi -> header();

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
            <li class="active"><a href="http://student.cryst.bbk.ac.uk/~jhurst03/bootstrap.html">Home</a></li>
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
          </ul>
        </div><!--/.nav-collapse -->
      </div>
    </div>
      

<div class="row">
<div class="col-md-8">
<div class="panel panel-default">
<div class="panel-heading">DNA Sequence</div>
<div class="panel-body">
<span style ="font-family: Courier;">
__EOF

my @results = GenBankAnalysis::FindRestrictionSites($accno,@{$enzymes{$enzyme}}[0],@{$enzymes{$enzyme}}[1]);

my %matches = %{@results[0]};

 

my $string = $gene[4];

my @cstart = sort { $a <=> $b } keys %matches;
my @cfinish = sort { $a <=> $b } values %matches;
my $ccount = 0;
print $cstart[0];
for (my $sequence=0; $sequence < length($string); $sequence++){

my $base = substr($string, $sequence, 1);
if ($sequence == @cstart[$ccount]){
print "<span style=\"background-color: #FFFF00\">";
}

print $base;
if (($sequence+1)%100 == 0){
print "<br>";
}
if ($sequence == @cfinish[$ccount]){
print "</span>";
$ccount++;
}
}


print <<__EOF;
</span>
</div>
</div>
</div>
<div class="col-md-4" style="float:left;">
Find Restriction Enzyme Site
<form action='/cgi-bin/cgiwrap/jhurst03/restriction.pl' method='post'>
<div class="row">
<div class="col-xs-4">
<select class="form-control" name="enzyme">
__EOF

foreach my $enzyme(keys(%enzymes)) {
	print "<option value=\"$enzyme\">$enzyme</option>";
}

print <<__EOF;
</select>
</div>
</div>
<p><p>
Or input your own sequence:
<input type="text" name="form" size="10" maxsize="10"/></p>
<p><button type="submit" name="submit" value="$accno"/>Submit</button></p>
</form>
</div>
<!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
<!-- Include all compiled plugins (below), or include individual files as needed -->
<script src="js/bootstrap.min.js"></script>
</body>
</html>
__EOF
