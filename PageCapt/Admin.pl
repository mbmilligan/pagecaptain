#!/usr/bin/perl

# Quick hack to allow assignment of items

use Pg;
use CGI qw/:standard/;

do 'tables.pl';

$magic_tag = "<QUERY>";
$template = "query.html";

my $function = param('function');
my $index = param('index');
my $owner = param('owner');
my $type = param('type');

# The usual security policy
my $uid = cookie(-name=>'ScavAuth');
ReLogin("<h2>You don't have permission to do this.</h2>") unless $uid == 1;

my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");

my $users = $conn->exec("select owner, nick from users order by owner");
my $user_popup = "<SELECT name=\"owner\">\n";

while ( ( my $uid, my $nickname ) = $users->fetchrow )
  { $user_popup .= "<OPTION value=\"$uid\">$nickname</OPTION>\n"; }
$user_popup .= "</SELECT>\n";

my $type_popup = "<SELECT name=\"type\">\n";
for $key ( keys %category )
  { $type_popup .= "<OPTION value=\"$category{$key}\">$key</OPTION>\n" }
$type_popup .= "</SELECT>\n";

my @cats = sort { $category{$a} <=> $category{$b}; } keys %category;


open HTML, $template;
print header;

while (<HTML>) {
  if ( /$magic_tag/ ) { admin_edit(); }
  else { print; }
}

exit;

sub admin_edit {

  big_table() unless $function;
  my $query = "update list SET";
  if ( $owner ) { $query .= "owner = $owner "; }
  if ( $type ) { $query .= "type = $type "; }
  $query .= "where index = $index";
  $conn->exec($query);

}

sub big_table {

  my $query = "SELECT index, description, type, owner from list order by index";
  my $result = $conn->exec($query);
  my $n = $result->ntuples;


  print "<Table border=\"1\">
<TR><TD>Item<TD>Description<TD>Owner<TD>Category</TR>";

  for $i ( 0 .. $n ) { gen_row( $result ) };

print "</Table>";

}

sub gen_row {

  my $result = shift;
  ( my $r_index,
    my $r_desc,
    my $r_type,
    my $r_owner ) = $result->fetchrow;

  print "<TR>\n";
  print "<TD>$r_index</TD>\n";
  print "<TD>$r_desc</TD>\n";

  print "<TD>\n";
  print "<FORM action=\"Admin.pl\" method=\"POST\">";

  unless ( $r_owner ) { print $user_popup, "\n" }
  else { print "<A href=\"User.pl?uid=$r_owner\">User Number $r_owner</A>"; }

  print "<TD>\n";

  unless ( $r_type ) { print $type_popup, "\n" }
  else { print "$cats[$r_type]"; }

  print "<input type=\"HIDDEN\" name=\"function\" value=\"1\">\n";
  print "<input type=\"SUBMIT\" value=\"Enter\">\n";
  print "</FORM>\n";
  print "</TR>\n";
}
