#!/usr/bin/perl
#################################################################
# Restriction.pl by Jeffrey Hurst				#
#								#
# Using Bootstrap v3.1.1 by Twitter				#
#								#
# Gets the details for a pre-defined enzyme or user inputted	#
# sequence, passes it to FindRestrictionSites, then displays   	#
# the results on the DNA sequence by highlighting them in 2	#
# colours. Contains the form again to try different enzymes.	#
#								#
#################################################################
use GenBankAnalysis;
use CGI;
use strict;
my $cgi = new CGI;
my $accno = $cgi->param("submit");
my $enzyme = $cgi->param("enzyme");
my $defseq = $cgi->param("form");

# get DNA sequence and enzyme details
my @detail = GenBankAnalysis::GetDetail($accno);
my @gene = @{@detail[0]};
my %enzymes = %{@detail[3]};

# define the enzyme details
my $enzseq = @{$enzymes{$enzyme}}[0];
my $enzcut = @{$enzymes{$enzyme}}[1];

#was the text form filled out correctly?
if ($defseq ne ""){
	my @defret = split(/:/, $defseq); #split the form
	if ($defret[0] =~ /[^ACGTNMRWYSKHBVD]/i || $defret[1] =~ /[^0-9]/){ #is it usable?
		$enzyme = "ERROR: non-nucleotide code found";
		$enzseq = "";
		$enzcut = "";		
	}	
	else {
		$enzseq = $defret[0];
		$enzcut = $defret[1];
		$enzyme = "user defined:",$defseq;
	}
}
			
#Build HTML page
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
            	<li class="active"><a href="http://student.cryst.bbk.ac.uk/~jhurst03/index.html">Home</a></li>
          	</ul>
        </div><!--/.nav-collapse -->
      	</div>
    	</div>    

	<div class="row">
	<div class="col-md-9">
	<h2>Restriction Enzyme Result:</h2>
__EOF
if ($enzyme =~ m/ERROR/){ #show warning panel if incorrect
	print <<__EOF;
	<div class="panel panel-danger">
	<div class="panel-heading"><strong>$enzyme</strong></div>
	<div class="panel-body">
		<span style ="font-family: Courier;">
__EOF
}
else{
	print <<__EOF;
	<div class="panel panel-default">
	<div class="panel-heading"><strong>Restriction Enzyme: $enzyme</strong></div>
	<div class="panel-body">
	Cutting sites are highlighted. Cut is shown by change from yellow to magenta.<p><p>
		<span style ="font-family: Courier;">
__EOF
}

#match against sequence
my @results = GenBankAnalysis::FindRestrictionSites($accno, $enzseq, $enzcut);

my %matches = %{@results[0]};

my $string = $gene[4];

#sort into arrays as hash will be scrambled
my @cstart = sort { $a <=> $b } keys %matches;
my @cfinish = sort { $a <=> $b } values %matches;
my $ccount = 0;

for (my $sequence=0; $sequence < length($string); $sequence++){

	my $base = substr($string, $sequence, 1);

	if ($sequence == @cstart[$ccount]){
		print "<span style=\"background-color: #FFFF00\">"; #start highlighting match
	}

	if ($sequence == @cstart[$ccount]+$enzcut){
		print "</span><span style=\"background-color: #FF00FF\">"; #switch colour if cut is at this point	
	}
	print $base;
	if (($sequence+1)%1000 == 0){ #give base count on the side
		print " ",$sequence+1;
	}
	
	if (($sequence+1)%100 == 0){ #new line
		print "<br>";
	}
	if ($sequence == @cfinish[$ccount]){ #finish highlight
		print "</span>";
		$ccount++;
	}
}


#create form for restriction enzyme search
print <<__EOF;
	</span>
	</div>
	</div>
	</div>
	
	<div class="col-md-3" style="float:left;">
	<h3>Restriction Enzyme Search</h3>
	<div class="panel panel-default">
	<div class="panel-heading"><strong>Search form</strong></div>
	<div class="panel-body">
		<form action='/cgi-bin/cgiwrap/jhurst03/restriction.pl' method='post'>
		Select an enzyme:
		<div class="row">
		<div class="col-xs-6">
			<select class="form-control" name="enzyme">
__EOF

#fill dropdown with enzyme names
foreach my $enzyme(keys(%enzymes)) {
	print "<option name =\"enzyme\" value=\"$enzyme\">$enzyme</option>";
}

print <<__EOF;
			</select>
		</div>
		</div>
		<p><p>.
		Or input your own sequence and cutting site, cutting offset is given by a number, e.g. 1 cuts one base downstream of 5' end. 
		Use a colon to seperate them, e.g. ATTCT:2<p> 
		<input type="text" name="form" size="20">
		<p><button type="submit" name="submit" value="$accno"/>Submit</button></p>
		</form>
	</div>
	</div>
	</div>
	
	<!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
	<!-- Include all compiled plugins (below), or include individual files as needed -->
	<script src="js/bootstrap.min.js"></script>
</body>
</html>
__EOF
