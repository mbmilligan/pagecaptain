#!/usr/bin/perl

=head1 NAME

ClaimItem.pl - a CGI program in the ScavCode PageCaptain app

=head1 DESCRIPTION

This CGI program is a single-purpose tool to assign a chosen item to
the currently logged-in user.  It is called from the
F<admin_edit.html>, F<owner_edit.html>, and F<update.html> template
files, which are filled in by L<getquery.pl> and other programs.

On execution, barring fatal errors and provided that the I<redir>
parameter is not set, the F<query.html> template will be printed to
the client, with the line containing the string C<E<lt>QUERYE<gt>>
replaced by output information.  Most errors will result in the
F<relogin.html> template being used instead, with an informational
message.

This program loads F<tables.pl>.

This program uses C<CGI> and C<Pg>.

=cut

use Pg;
use CGI qw/:standard/;

do 'tables.pl';

$magic_tag = "<QUERY>";
$template = "query.html";

=head2 CGI Parameters

=over 4

=item I<uid>

The UID number of the user to whom the item should be assigned.  Only
used if the client is logged in as UID 1 (administrator).

=item I<index>

Required parameter specifying the index number of the item to be
modified.  Although required, this condition is not checked, and there
is no defined failure behavior.

=item I<unclaim>

If this parameter is set to a true value, the item will be "unclaimed"
by setting its owner number to C<null>.

=item I<redir>

If set to a true value, this parameter specifies a string that will be
treated as a URI sent to the client in an HTTP redirect; this is in
lieu of outputting a filled template.

=back

=cut

my $assign_uid = param('uid');
my $item = param('index');
my $unclaim = param('unclaim');
my $redir_target = param('redir');

=head1 IMPLEMENTATION

=head2 Main Body

Read the CGI parameters into file-scoped lexical variables.

Retrieve the client log-in UID from the I<ScavAuth> cookie into I<$auth>.  If I<$auth> == 1 and I<uid> is set, use the provided UID.  Otherwise, we will assign the item to the UID from I<ScavAuth> and ignore I<uid>.  If the cookie does not exist, call C<ReLogin()> asking the user to log in.

=cut

# The usual security policy
my $auth = cookie(-name=>'ScavAuth');
my $uid = $auth;

$uid = $assign_uid if $auth == 1 && $assign_uid;
ReLogin("<h2>Maybe you should log in first.</h2>") unless $uid;

=pod

Call C<claim_result()> and store its return value as I<$message>.

If I<redir> is set, print an HTTP redirect to the value of I<redir>.
Note that no validation is performed on this variable.

Otherwise, open the default template (F<query.html>, defined at top),
and replace lines containing the I<magic> string with I<$message>.

Either way, exit.

=cut

my $output = &claim_result;

if ($redir_target)
  { print redirect($redir_target);  
  } else
  {
    open HTML, $template;
    print header;
    
    while (<HTML>) {
      if ( /$magic_tag/ ) { print $output; }
      else { print; }
    }
  }

exit;

=head2 C<claim_result()>

=over 4

=item Synopsis

Perform the database operations needed to fulfill the request, and
return an informational output string to be substituted into the
template.

=item Arguments

None.  However, this routine expects to find I<$item>, I<$uid>, I<$auth>, and I<$unclaim> defined as file-scoped lexicals.

=back

=cut

sub claim_result {

  my $output = "<P>Attempting to (un)claim item number $item for user $uid.</P>\n";

=pod

Establish the database connection -- we need to check if the item is
owned.  Get a connection to the database using an account with
permission to SELECT the users table.

=cut

  my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
  my $query = "SELECT owner from list where index = $item";
  my $result = $conn->exec($query);

  ( my $r_owner ) = $result->fetchrow;

=pod

Check that the operation is authorized.  I<$r_owner> is the owner of
the item in the database.  Do nothing and return an error message
unless C< I<$r_owner> == 0 ) || ( I<$r_owner> == I<$uid> ) || (
I<$auth> == 1 >.

=cut

  do { $output .= "<h2>You do not have permission to do this. Already claimed by $r_owner.</h2>\n"; 
       return $output; 
     } unless ( $r_owner == 0 ) || ( $r_owner == $uid ) || ( $auth == 1 );

=pod

Construct an SQL statement setting the item owner to I<$uid>, or if
I<$unclaim> is set, to C<null>.  Run this statement and return a
confirmation message.  The exit status of the SQL operation is not
checked.

=cut

  my $action = "claimed";
  if ( $unclaim ) { $uid = "null"; $action = "unclaimed"; }
  $query = "UPDATE list SET owner = \'$uid\' WHERE index = $item";
  $result = $conn->exec($query);

  do { $output .= "<h2>You have successfully $action item number $item</h2>\n";
       return $output;
     }
}

=head2 C<ReLogin( I<$message> )>

=over 4

=item Synopsis

Output HTTP headers and the F<relogin.html> template file, with any
line containing the string C<E<lt>RELOGINE<gt>> replaced by the passed
message string.  Exit rather than return.

=item Arguments

I<$message> is the string to be output.

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
