#!/usr/bin/perl

use CGI qw/:standard/;
use Pg;

do 'tables.pl';

my $magic_tag = "<QUERY>";
$source = param('source'); if ( $source !~ /html$/ ) { die "You fool!"; }

open SOURCE, $source;

print header;

while (<SOURCE>)
  { if ( /$magic_tag/ ) { updatelist() } else 
      { if ( /<IDX>/ ) { $idx = param('index'); s/<IDX>/$idx/; print $_; } 
	elsif ( /<IDX_NEXT>/ ) { $idx = param('index')+1; s/<IDX_NEXT>/$idx/; 
			      print $_; } 
	elsif ( /<IDX_PREV>/ ) { $idx = param('index')-1; s/<IDX_PREV>/$idx/; 
			      print $_; } 
	else {print $_; } } }

sub updatelist
  { $i = param('index');
    $i =~ s/[^0-9]//g;
    $score = param('score');
    $score =~ s/[^0-9.\/]//g;
    if ( $score eq "" ) { $s = ""; } else 
      { $s = "points = $score"; }
    $c = param('cat');
    $cat = $category{$c};
    if ( $cat eq "" ) { $c = ""; } else
      { $c = "type = $cat"; }
    $sta = param('status');
    $st = $status{$sta};
    if ( $st eq "" ) { $t = ""; } else
      { $t = "status = $st"; }
    $notes = param('notes');
    if ( $notes eq "" ) { $n = "" } else 
      { $notes =~ s/'/\\'/g;
	$n = qq!notes = notes || '<P>$notes</P>'!; }
    $cmd = $s;
    foreach ( ($c, $t, $n) ) 
      { if ( $_ ne "" && $cmd ne "" ) { $cmd = "$cmd, $_"; } else
	{ if ( $cmd eq "" ) { $cmd = $_; } } }
    $q = "UPDATE list SET $cmd WHERE index = $i";

    # This works. We don't need to keep printing the query.
    # print "$q<P>\n";
    $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
    $result = $conn->exec($q);

    my $error_status = $conn->errorMessage;
    my $debug = 0;
    print "<P>QUERY: $q</P>" if $error_status || $debug;
    print "<P>$error_status</P>" if $error_status;

    $result = $conn->exec("select * from list where index = $i order by index");
    $count = $result->ntuples;

    # Print a color code
    print "Color code: \n";
    print "<Table border=1>";
    foreach ( keys %status )
	{ $colstr = "";
	  if ( $statcol{$_} ne "" ) { $colstr = " bgcolor=\"$statcol{$_}\""; }
	  print "<TD$colstr>$_</TD>"; }
    print "</Table>\n<P>\n";

    # Print table headers
    print "<Table cellpadding=3 border=2 width=100%>
           <TR><TH>Index<TH>Points<TH>Category<TH>Item<TH>Scoring<TH>Notes</TH></TR>\n";

    # Loop to generate table rows

    @stats = sort { $status{$a} <=> $status{$b}; } keys %status;
    @cats = sort { $category{$a} <=> $category{$b}; } keys %category;

    for ( $i = 0; $i < $count; $i++ )
      { $r_index = $result->getvalue( $i, 0 );
	$r_score = $result->getvalue( $i, 1 );
	$r_type = $result->getvalue( $i, 2 );
	$r_status = $result->getvalue( $i, 3 );
	$r_desc = $result->getvalue( $i, 4 );
	$r_comm = $result->getvalue( $i, 5 );
	$r_notes = $result->getvalue( $i, 6 );

	$color = $statcol{$stats[$r_status]};
	$cat = $cats[$r_type];

	print "<tr bgcolor=\"$color\">";
	print "<td>$r_index</td>";
	print "<td>$r_score</td>";
	print "<td>$cat</td>";
	print "<td>$r_desc</td>";
	print "<td>$r_comm</td>";
	print "<td>$r_notes</td></tr>\n"; };
    
    print "</Table>\n"; }

# This should strip out leading and trailing space, and escape any 
# single-quotes (but not unescape them).
sub Sanitize {

  my $string = $_[0];

  $string =~ s/^\s+//gm;
  $string =~ s/\s+$//gm;

  $string =~ s/^'/\\'/mg;
  $string =~ s/([^\\])'/$1\\'/g;

  return $string;
}
