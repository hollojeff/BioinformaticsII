#!/usr/bin/perl
#################################################################
# Detail.pl by Jeffrey Hurst					#
#								#
# Using Bootstrap v3.1.1 by Twitter				#
#								#
# Builds a page, using the module GetDetail to show the Amino	#
# acid sequence, coding sequence, codon table and DNA sequence. #
# Also includes a form to search the DNA sequence using 	#
# restriction enzyme sequences or an inputted one.		#
#								#
#################################################################
use GenBankAnalysis;
use CGI;
use strict;
my $cgi = new CGI;
my $accno = $cgi->param('action');

#Call GetDetail to retrieve data 
my @detail = GenBankAnalysis::GetDetail($accno);
my @gene = @{@detail[0]};
my %exon = %{@detail[1]};
my %codons = %{@detail[2]};
my %enzymes = %{@detail[3]};


#Create HTML page
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
	<div class="search-form">
		<h2>Detail of $gene[2]</h2>
		<h3>Accession no:$gene[0] Location:$gene[1] Product:$gene[3]</h3>
__EOF

#sort out amino acid and coding sequences

my $aminosequence = $gene[6];
my $codingsequence = $gene[5];

#split sequence into strings of 100 characters
my @codseq = unpack("(A100)*", $codingsequence);
my @amiseq = unpack("(A100)*", $aminosequence);

print <<EOF__;
	<div class="panel panel-default">
	<div class="panel-heading"><strong>Amino Acid Sequence</strong></div>
	<div class="panel-body">
	<span style ="font-family: Courier;">
EOF__

#print sequences
for (my $i=0; $i < scalar @amiseq; $i++){
	print $amiseq[$i],"<br>";
}

print <<EOF__;
	</span>
	</div>
	</div>
	<div class="panel panel-default">
	<div class="panel-heading"><strong>Coding Sequence</strong></div>
	<div class="panel-body">
		<span style ="font-family: Courier;">
EOF__

for (my $i=0; $i < scalar @codseq; $i++){
	print $codseq[$i],"<br>";
}

print <<EOF__;
		</span>
	</div>
	</div>
	<div class="panel panel-default">
	<div class="panel-heading"><strong>Codon Table</strong></div>
	<div class="panel-body">
	Table reads: Codon Triplet, Amino Acid letter, Genome Frequencey, Genome Ratio, Gene Frequency, Gene Ratio<p><p> 
		<span style ="font-family: Courier;">
EOF__

#Call codon table variables

#create array with codons in order for table,
#also as ref will be disordered.

my @codlet = ("U","C","A","G");
my @codtab;
my @codarr;

for (my $i=0; $i<4; $i=$i + 1){
	my $first = $codlet[$i];
	for (my $j=0; $j<4; $j++){
		my $second = $codlet[$j];
		for (my $k=0; $k<4; $k++){
			my $third = $codlet[$k];
			my $codtrip = $first.$second.$third; #create triplet
			push (@codtab, $codtrip);
			$codtrip =~ s/U/T/g; #switch U for T to get key
			my @codarr = @{$codons{$codtrip} }; #Dereference
			foreach my $codelm (@codarr) {
				push (@codtab, $codelm); #add deref hash values to array
			}
		}
	}
}

print <<__EOF;

	       
	<table border="1">
		<tr>
__EOF
#build the table
for (my $i = 0; $i < scalar @codtab; $i++){
	if ($codtab[$i] =~ m/[AGCU]{3}/){ #if triplet, make bold
		print "<td><b>$codtab[$i]</b></td>";
	}
	else{
		print "<td>$codtab[$i]</td>";
	}
	if (($i+1)%24 == 0){ # new row
		print "</tr><tr>";
	}
}
print "</table>";

print <<EOF__;
		</span>
	</div>
	</div>
	<div class="panel panel-default">
	<div class="panel-heading"><strong>DNA Sequence</strong></div>
	<div class="panel-body">
	Exons are highlighted in yellow.<p><p>
		<span style ="font-family: Courier;">
EOF__

#Call DNA sequence and exon details

my $string = $gene[4];

# exons are unsorted, so adding the ordered values into 2 arrays
my @cstart = sort { $a <=> $b } keys %exon;
my @cfinish = sort { $a <=> $b } values %exon;
my $ccount = 0;

for (my $sequence=0; $sequence < length($string); $sequence++){

	my $base = substr($string, $sequence, 1);
	if ($sequence == @cstart[$ccount]){
		print "<span style=\"background-color: #FFFF00\">"; #if exon starts, highlight in yellow
	}
	if ($sequence == @cfinish[$ccount]){
		print "</span>"; #stop highlighting
		$ccount++;
	}
	print $base;
	if (($sequence+1)%1000 == 0){ #give base count on the side
		print " ",$sequence+1;
	}
	if (($sequence+1)%100 == 0){ #new line
		print "<br>";
	}
}

#create form for restriction enzyme search
print <<__EOF;
	</span>
	</div>
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
