#!/usr/bin/perl

use CGI qw/:standard/;
use Pg;

$debug = 0;

do 'tables.pl';

my $magic_tag = "<QUERY>";
$source = param('source'); if ( $source !~ /html$/ ) { die "You fool!"; }

open SOURCE, $source;

print header;

while (<SOURCE>)
  { if ( /$magic_tag/ ) { gentable() } else 
      { if ( /<IDX>/ ) { $idx = param('index'); s/<IDX>/$idx/; print $_; } 
	elsif ( /<IDX_NEXT>/ ) { $idx = param('index')+1; s/<IDX_NEXT>/$idx/; 
			      print $_; } 
	elsif ( /<IDX_PREV>/ ) { $idx = param('index')-1; s/<IDX_PREV>/$idx/; 
			      print $_; } 
	else {print $_; } } }

sub gentable
  { 
    my $query = parse_query();

    # Are we logged in?
    $auth_owner = cookie(-name=>'ScavAuth');

    my $conn = Pg::connectdb("dbname=scavlist user=dummy");
    my $result = $conn->exec($query);
    my $n = $result->ntuples;
    my $error_status = $conn->errorMessage;

    print "<P>QUERY: $query</P>" if $debug || $error_status;
    print "<P>$error_status</P>" if $error_status;

    print "<P>Your search produced $n results, shown below:</P>";

    color_code();

    # Print table headers
    # | Index | Owner | Description | Scoring | Notes | Type | Points | 
    # <COL span="2" width="0*"><COL width="2*"><COL span="2" width="1*">
    #    <COL span="2" width="1*">
    print <<EOF;
    <Table border=1 cellpadding=3 width="100%">
    <TR>
    <TH>Index<TH>Owner<TH>Item<TH>Scoring<TH>Notes<TH>Category<TH>Points</TH>
    </TR>
EOF

    # Loop to generate table rows

    @stats = sort { $status{$a} <=> $status{$b}; } keys %status;
    @cats = sort { $category{$a} <=> $category{$b}; } keys %category;

    for ( 0 .. $n-1 )
      { print gen_query_row( $result, $auth_owner ); };
    
    print "</Table>\n"; 
  }

# Parse query and generate query string (requires tables.pl)
sub parse_query {

my $query;
my $type = param('type');

my $sorting = param('sort');
if ( $sorting eq "points" ) { $sorting .= " DESC"; }
if ( $sorting ne "index" ) { $sorting .= ", index"; }

if ( $type eq "keyword" )
  { my $search_key = param('key');
    $query = "select * from list where ";
    $query .= "description ~* \'$search_key\' OR ";
    $query .= "scoring ~* \'$search_key\' OR ";
    $query .= "notes ~* \'$search_key\' ";
    $query .= "order by $sorting"; 
  }

if ( $type eq "catsort" )
  { my $search_cat = param('cat');
    my $cat_cond;
    
    if ( $search_cat eq "all" ) {$cat_cond = "" } else
      { $cat_cond = "where type = $category{$search_cat}"; }
    $query = "select * from list $cat_cond order by $sorting"; 
  }

if ( $type eq "index" )
  { my $index = param('index');
    $query = "select * from list where index = $index"; 
  }

return $query;
}

# Print a color code (requires tables.pl)
sub color_code {

  print "Color Code: \n";
  print "<Table border=1>";
  foreach ( keys %status )
    { $colstr = "";
      if ( $statcol{$_} ne "" ) { $colstr = " bgcolor=\"$statcol{$_}\""; }
      print "<TD$colstr>$_</TD>"; }
  print "</Table>\n<P>\n";

}

# Return an HTML table row for our query
# gen_query_row( $result, $auth_owner );
# | Index | Owner | Description | Scoring | Notes | Type | Points | 
sub gen_query_row {

  my $result = shift;
  my $auth_owner = shift;

  ( my $r_index,
    my $r_points,
    my $r_type,
    my $r_status,
    my $r_desc,
    my $r_scoring,
    my $r_notes,
    my $r_owner ) = $result->fetchrow;
  
  # If needed, look up the owner
  my $owner_link;
  if ( $r_owner )
    { my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
      my $query = "SELECT nick, name FROM users WHERE owner = $r_owner";
      my $result = $conn->exec($query);
      ( my $r_nick, my $r_name ) = $result->fetchrow;
      my $text = $r_nick;
      $text = $r_name if $r_name;
      $owner_link = "<A href=\"User.pl?uid=$r_owner\">$text</A>";
    }

  my $color = $statcol{$stats[$r_status]};
  my $cat = $cats[$r_type];
  
  my $form = choose_item_form( $auth_owner, $r_owner, $r_index );
  my $return_string = <<EOF;

<tr bgcolor=$color>
<td>$r_index<P>
$form
</td>
<td>$owner_link</td>
<td>$r_desc</td>
<td>$r_scoring</td>
<td>$r_notes</td>
<td>$cat</td>
<td>$r_points</td>
</tr>

EOF

  return $return_string;
}

sub choose_item_form {

  my $owner = shift;
  my $item_owner = shift;
  my $item_index = shift;

  my $form_admin = <<EOF;
<form action="getquery.pl" method="get">
	<input type="hidden" name="type" value="index">
	<input type="hidden" name="source" value="admin_edit.html">
	<input type="hidden" name="index" value="$item_index">
	<input type="submit" value="Admin">
</form>
EOF

  my $form_edit = <<EOF;
<form action="getquery.pl" method="get">
	<input type="hidden" name="type" value="index">
	<input type="hidden" name="source" value="owner_edit.html">
	<input type="hidden" name="index" value="$item_index">
	<input type="submit" value="Edit">
</form>
EOF

  my $form_view = <<EOF;
<form action="getquery.pl" method="get">
	<input type="hidden" name="type" value="index">
	<input type="hidden" name="source" value="annotate.html">
	<input type="hidden" name="index" value="$item_index">
	<input type="submit" value="Note">
</form>
EOF

  my $form_claim = <<EOF;
<form action="getquery.pl" method="get">
	<input type="hidden" name="type" value="index">
	<input type="hidden" name="source" value="update.html">
	<input type="hidden" name="index" value="$item_index">
	<input type="submit" value="Ed/Claim">
</form>
EOF

  # If we are admin, we can do cool stuff with it: $form_admin
  # If nobody owns this item, anyone can edit or claim it: $form_claim
  # If this user owns this item, they get full privileges: $form_edit
  # If someone else owns this item, they can only annotate: $form_view
  # If this user isn't logged in, they can only annotate: $form_view

  my $form_choice = $form_view;
  if ( $owner )
    { $form_choice = $form_claim unless $item_owner;
      $form_choice = $form_edit if $owner == $item_owner;
      $form_choice = $form_admin if $owner == 1;
    }

  return $form_choice;
}
