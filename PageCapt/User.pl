#!/usr/bin/perl

=head1 NAME

User.pl - a CGI program in the ScavCode PageCaptain App

=head1 DESCRIPTION

This CGI program generates an HTML interface providing the ability to view and
edit information for users on the system, customized to the user calling the
program.  It is called directly from the F<search.html> form, and provides a
control in the F<relogin.html> template.  L<AddUser.pl> may redirect the
client to this script, and L<Admin.pl> and L<getquery.pl> both emit HTML
controls linking to this script.

Upon execution, the F<query.html> template will be printed to the client, with
returned data and HTML controls replacing the string, C<E<lt>QUERYE<gt>>.  In
case of a fatal error condition, C<ReLogin> will be called instead, which
returns the F<relogin.html> template and replaces the string
C<E<lt>RELOGINE<gt>> with an informational message.

This program uses C<CGI> and C<Pg>.

This program loads F<tables.pl>.

=head2 CGI Parameters

=over 4

=item I<uid>

The UID number of the user whose information is being requested.  The controls
available on the resulting page will depend upon the user performing the
request.  If not provided, the information page for the requesting user will
be retrieved by default.

=back

This program establishes the identity of the requesting user by checking the
I<ScavAuth> cookie.  Since this program may only be used by logged-in users,
the absence of this cookie is a fatal error.

If the requesting user is different from the user whose information is
requested, no editing controls will be provided.

=cut

use CGI qw/:standard/;
use Pg;

do 'tables.pl';

$template = "query.html";
$magic_tag = "<QUERY>";
$debug = 0;

=head1 IMPLEMENTATION

=head2 Main Body

Anyone can view user information; they only get the editing interface
if they have a cookie for the requested UID.

Begin by recording the value of the I<uid> parameter and the
I<ScavAuth> cookie.  If I<uid> is not defined, set it to the value
from the cookie.  Set the authority flag if the I<uid> parameter and
the cookie agree.

Notice that we use the I<uid> value from here on out -- it overrides
the cookie.  The exception is that the cookie is used by the row
generator to select controls.

=cut

$auth = 0;

my $owner = param('uid');
my $uid = cookie(-name=>'ScavAuth');
$owner = $uid unless $owner;

if ( $uid == $owner )
  { $auth = 1; }

=pod

Get a connection to the database using a username with permission to
read the users table.  This information is hardcoded in the script.

If I<uid> is undefined (not specified and not logged in) abort by
calling C<ReLogin()> with an informational message.

Otherwise, continue by opening the template file (hardcoded as
F<query.html>) and print it to the client, printing the output of
C<user_page()> when a line containing the "magic string" is
encountered. 

Exit when done.

=cut

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

=head2 C<user_page( I<$uid>, I<$user>, I<$connection> )>

=over 4

=item Synopsis

Generate a user information page and return the HTML in a string.
This page will contain the outputs of C<user_info()>, C<user_items()>,
and if authorized, C<user_edit()>, in that order; these functions
produce elements of the page as their names suggest.

As a special case, C<I<$uid> = 'nobody'> gives a list of un-claimed
items.

=item Arguments

I<$uid> is the numeric UID of the user whose page is to be generated,
or the string "nobody".

I<$user> is the numeric UID of the logged-in user making the request.

I<$connection> is a C<Pg> object corresponding to an open database
connection. 

=back

This function assumes I<$uid> is non-null, since we should have
already checked for that condition and done C<ReLogin()>.

=cut

sub user_page {

  my $owner = shift;
  my $uid = shift;
  my $conn = shift;
  my $output;

  $output .= user_info( $owner, $conn ) unless $owner == 'nobody';
  $output .= "\n<HR>\n";
  $output .= user_items( $owner, $conn, $auth, $uid );
  $output .= "\n<HR>\n";
  $output .= user_edit( $owner, $conn ) if $auth;
  
  return $output;
}

=head2 C<user_info( I<$uid>, I<$connection> )>

=over 4

=item Synopsis

Get and return as HTML information for given user.

=item Arguments

I<$uid> is the UID of the user whose information is to be retrieved.

I<$connection> is an open C<Pg> connection object.

=back

=cut

sub user_info {

  my $owner = shift;
  my $conn = shift; 

=pod

C<select nick, name, address, phone, email, contact from users where
owner = I<$uid>> Assume we only get one row back, and save it.  If no
row is returned, return a "no such user" string instead of a table.

=cut

  my $result = $conn->exec("select nick, name, address, phone, email, contact from users where owner = $owner");
  my @user = $result->fetchrow;

  my $output;

  unless ( @user ) {
    $html = "<H3>No user has UID $owner</H3>"; 
    return $html; }

=pod

Write an HTML table into the output buffer, and return it.

  Login | Name | Address | Phone # | E-mail | Other

=cut

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

=head2 C<user_items( I<$uid>, I<$connection>, I<$auth>, I<$user> )>

=over 4

=item Synopsis

Get and return as an HTML table the items claimed by a user.  This
function is closely adapted from C<gentable()> (see
L<getquery.pl/"C<gentable()>">), and has essentially the same
implementation, except that it searches on the I<owner> field.

Follows the same "nobody" convention as L<"user_page()">.

=item Arguments

I<$uid> is the UID of the user whose items should be reported, or the
string, "nobody", to retrieve a list of unclaimed items.

I<$connection> is an open C<Pg> database connection.

I<$auth> is the authority flag, indicating that the user is requesting
his/her own page.

I<$user> is the UID of the user invoking this request.

=back

=cut

sub user_items {

  my $owner = shift;
  my $conn = shift;
  my $auth = shift;
  my $uid = shift;
  my $output;

=pod

Select everything from list by owner, or C<owner is null> if I<$uid>
is "nobody".  On error, append informational messages to the output
buffer.  If no rows are returned, return a message "This user is
responsible for no items" as HTML.

Append the output of C<color_code()> to the output.  Append table
headers conforming to:

  <TH>Index<TH>Points<TH>Category<TH>Item<TH>Scoring<TH>Notes</TH>

Loop over the returned rows, appending the output of
C<gen_query_row()>.  Finally, append a table closing tag and return
the output buffer.

=cut

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

=head2 C<user_edit( I<$uid>, I<$connection> )>

=over 4

=item Synopsis

Return HTML code for a form to edit user information.

=item Arguments

I<$uid> is the user whose information should be modified by the HTML
controls.

I<$connection> is an open C<Pg> database connection.

=back

=cut

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

=pod

Fetch all information for this user from the database.  Start the
output buffer with an informational header.

If the I<nick> field is the same as the UID, generate an input field
for a new I<nick>.  Otherwise generate a hidden field containing the
current login ID.

Append to the buffer a form invoking L<AddUser.pl>, with the "nick"
control described above, and inputs to accept new values for the
I<name>, I<address>, I<phone>, I<email>, I<contact>, and I<password>
fields.  SUBMIT and RESET buttons are emitted, and finally a hidden
field setting the I<edit> CGI parameter.  Return this buffer.

=cut

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

=head2 C<color_code()>

=over 4

=item Synopsis

Return a color code as an HTML table (requires tables.pl), describing
the correspondance between row color and item status in item data
tables.  Identical to the function described at
L<genquery.pl/"C<color_code()>">, except that it returns, instead of
prints to the client, its output.

=item Arguments

None.

=back

=cut

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

=head2 C<gen_query_row( I<$result>, I<$auth>, I<$uid> )>

=over 4

=item Synopsis

Return an HTML table row for an item in the list.  Derived from the
function described at L<gentable.pl/"C<gen_query_row()>">, with
customizations to the output making it more appropriate for a user
information page.  Mostly, less information is displayed.

=item Arguments

I<$result> is a C<Pg> query result object for this item.

I<$auth> is the authority flag, indicating that the user is requesting
his/her own information page.

I<$uid> is the UID of the requesting user.

=back

=cut

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

=head2 C<ReLogin( I<$message> )>

=over 4

=item Synopsis

Open the template file F<relogin.html> and replace lines containing
the magic string, C<E<lt>RELOGINE<gt>>, with the supplied message.

Does not return.  On EOF, exit with code 0.

=item Arguments

I<$message> is the string to be output in the template.

=back

=cut

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
