#!/usr/bin/perl

# View/Edit information for users on the system

use CGI qw/:standard/;
use Pg;

do 'tables.pl';

$template = "query.html";
$magic_tag = "<QUERY>";
$debug = 0;

# Anyone can view user information; they only get the editing interface
# if they have a cookie for the requested UID

$auth = 0;

my $owner = param('uid');
my $uid = cookie(-name=>'ScavAuth');
$owner = $uid unless $owner;

if ( $uid == $owner )
  { $auth = 1; }

# Notice that we use $owner from here on out -- it overrides the cookie.
# Not actually true -- $uid is used by the row generator

# Get a connection to the database with permission to get users
$conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");

# Output HTML
ReLogin("<H2>No user specified -- maybe you should log in.</H2>")
  unless $owner;

open HTML, $template;
print header;

while (<HTML>) {
  if ( /$magic_tag/ ) { print user_page( $owner, $uid, $conn ); }
  else { print; }
}

exit;

# The following all assume $owner is non-null, since we should have 
#   already checked for that condition and done ReLogin.

# Generate the user's page
sub user_page {

  my $owner = shift;
  my $uid = shift;
  my $conn = shift;
  my $output;

  # As a special case, $owner = 'nobody' gives a list of un-claimed
  # items. 

  $output .= user_info( $owner, $conn ) unless $owner == 'nobody';
  $output .= "\n<HR>\n";
  $output .= user_items( $owner, $conn, $auth, $uid );
  $output .= "\n<HR>\n";
  $output .= user_edit( $owner, $conn ) if $auth;
  
  return $output;
}

# Get and display as HTML information for given user
sub user_info {

  my $owner = shift;
  my $conn = shift; 

  my $result = $conn->exec("select nick, name, address, phone, email, contact from users where owner = $owner");
  my @user = $result->fetchrow;

  my $output;

  unless ( @user ) {
    $html = "<H3>No user has UID $owner</H3>"; 
    return $html; }

  $output = <<EOF;
<Table Border="1" align="center">
  <TR>
    <TD>Login
    <TD>Name
    <TD>Address
    <TD>Phone \#
    <TD>E-mail
    <TD>Other Contact Info
  </TR>
  <TR>
    <TD>$user[0]
    <TD>$user[1]
    <TD>$user[2]
    <TD>$user[3]
    <TD>$user[4]
    <TD>$user[5]
  </TR>
</Table>
EOF

  return $output;
}

# Get and display as HTML this user's claimed items
# Closely adapted from gentable in getquery.pl
sub user_items {

  my $owner = shift;
  my $conn = shift;
  my $auth = shift;
  my $uid = shift;
  my $output;

  my $query = "select * from list where owner = $owner order by index";
  $query = "select * from list where owner is null order by index" 
    if $owner == 'nobody';
  
  $result = $conn->exec($query);
  $n = $result->ntuples;
  $error_status = $conn->errorMessage;
  
  $output .= "<P>QUERY: $query</P>" if $debug;
  $output .= "<P>$error_status</P>" if $error_status;

  return "<P>This user is responsible for no items.</P>" if $n == 0;
  
  $output .= "<P>This user is responsible for $n items, shown below:</P>";
  
  $output .= color_code();
  
  # Output table headers
  $output .= <<EOF;
  <Table border=2 cellpadding=3 width="100%">
  <COL span=3 width="0*"><COL width="2*"><COL width="1*"><COL width="1*">
  <TR><TH>Index<TH>Points<TH>Category<TH>Item<TH>Scoring<TH>Notes</TH></TR>
EOF

  # Loop to generate table rows
  
  @stats = sort { $status{$a} <=> $status{$b}; } keys %status;
  @cats = sort { $category{$a} <=> $category{$b}; } keys %category;
  
  for $i ( 0 .. $n-1 )
    { $output .= gen_query_row( $result, $auth, $uid ); }
  
  $output .= "</Table>\n"; 

  return $output;
}

# Provide a form to edit user information, if authoritized to do so.
sub user_edit {

  my $owner = shift;
  my $conn = shift;
  my $query = "select * from users where owner = $owner";
  my $result = $conn->exec($query);

  ( undef,
    my $u_nick,
    my $u_name,
    my $u_address,
    my $u_phone,
    my $u_email,
    my $u_contact,
    my $u_password ) = $result->fetchrow;

  my $output = <<EOF;
<P><B>Below, you can edit your user information if desired. In particular, 
consider updating your contact information if it changes.</B></P>
EOF

  # If this is one with just a number, let them choose a new nickname
  my $nick_input;
  if ( $owner == $u_nick )
    { $nick_input = 
	"<P><B>Login handle:</B> <input type=\"text\" size=\"16\" name=\"nick\"> </P>" }
  else 
    { $nick_input = "<input type=\"HIDDEN\" name=\"nick\" value=\"$u_nick\">" }

  $output .= <<EOF;
    <form action="AddUser.pl" method="post">
      $nick_input
      <P><B>Full Name:</B><input type="TEXT" name="name" size="35" value="$u_name"> </P>
      <P>Address: <input type="TEXT" name="address" size="35" value="$u_address"></P>
      <P>Phone: <input type="TEXT" name="phone" size="16" value="$u_phone"></P>
      <P>Email: <input type="TEXT" name="email" size="35" value="$u_email"></P>
      <P>Other contact information:<BR>
	<textarea name="contact" rows="5" cols="35">$u_contact</textarea></P>
      <P>Password: <input type="PASSWORD" name="password" size="16" value="$u_password">
	Again, to be sure: <input type="PASSWORD" name="backup" size="16" value="$u_password"></P>
      <P>Please remember your password -- it doesn't have to be anything fancy;
	casual spy-proof is all we're looking for here. However, I haven't
	written in a way to change your password yet, so you'll have to bug me
	to change it if you lose yours.</P>
      <P><input type="SUBMIT" value="Update User"> <input type="RESET" value="Clear Form"></P>
      <input type="HIDDEN" name="edit" value="$owner">
    </form>
EOF

  return $output;
}

# Print a color code (requires tables.pl)
sub color_code {
  my $output;

  $output .= "Color Code: \n";
  $output .= "<Table border=1>";
  foreach ( keys %status )
    { $colstr = "";
      if ( $statcol{$_} ne "" ) { $colstr = " bgcolor=\"$statcol{$_}\""; }
      $output .= "<TD$colstr>$_</TD>"; }
  $output .= "</Table>\n<P>\n";

  return $output;
}

# Return an HTML table row for our query
# gen_query_row( $result );
sub gen_query_row {

  my $result = shift;
  my $auth = shift;
  my $uid = shift;

  ( my $r_index,
    my $r_points,
    my $r_type,
    my $r_status,
    my $r_desc,
    my $r_scoring,
    my $r_notes,
    my $r_owner,
    my $r_cost ) = $result->fetchrow;

  my $color = $statcol{$stats[$r_status]};
  my $cat = $cats[$r_type];

  my $form_choice = choose_item_form( $uid, $r_owner, $r_index );

  my $return_string = <<EOF;
<tr bgcolor=$color>
<td>$r_index<P>
$form_choice
</td>

<td>$r_points</td>
<td>$cat</td>
<td>$r_desc</td>
<td>$r_scoring</td>
<td>$r_notes</td></tr>

EOF

  return $return_string;
}

sub choose_item_form {

  my $owner = shift;
  my $item_owner = shift;
  my $item_index = shift;

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

  # If nobody owns this item, anyone can edit or claim it: $form_claim
  # If this user owns this item, they get full privileges: $form_edit
  # If someone else owns this item, they can only annotate: $form_view
  # If this user isn't logged in, they can only annotate: $form_view

  my $form_choice = $form_view;
  if ( $owner )
    { $form_choice = $form_claim unless $item_owner;
      $form_choice = $form_edit if $owner == $item_owner;
    }

  return $form_choice;
}

# This does not return.
sub ReLogin {

  my $magic_tag = "<RELOGIN>";
  my $filename = "relogin.html";

  # Expect a message string (HTML)
  my $message = $_[0];

  print header;

  open SOURCE, $filename;

  while (<SOURCE>) {
    if ( /$magic_tag/ ) { print $message."\n"; }
    else { print $_; }
  }

  exit 0;
}
