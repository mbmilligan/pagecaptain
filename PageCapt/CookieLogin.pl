#!/usr/bin/perl

=head1 NAME

CookieLogin.pl - a CGI program in the ScavCode PageCaptain app

=head1 DESCRIPTION

This CGI program is a utility that verifies a user id and password and, if successful, sets the I<ScavAuth> cookie.  The client is redirected.

This program uses C<CGI> and C<Pg>.

=cut

use CGI qw/:standard/;
use Pg;

$user = param('user');
$pass = param('pass');
$dest = param('dest');

=head2 CGI Parameters

=over 4

=item I<user>

Required parameter that contains the nickname (login ID) of the user
requesting a login cookie.

=item I<pass>

Required parameter containing the password for this user.

=item I<dest>

Required parameter giving the URI to redirect the client to.

=back

=head1 IMPLEMENTATION

=head2 Main Body

Read the CGI parameters into file-scoped lexicals.  Sanitize the
I<user> value by killing any "'" and \ (backslash) characters.

Create a cookie by calling C<cookie_login()>.  Exit unless a cookie is
created.  This should only happen if C<ReLogin()> was called, in which
case an error document has already been output to the client, but this
condition is not checked.

If successful, output an HTTP redirect to I<dest> that includes the
login cookie, and exit.

=cut

# Sanitize anything going to DB
$user =~ s/[\']//g;

$cookie = cookie_login( $user, $pass );
exit unless $cookie;

# We're in. Proceed as directed.
print redirect(-uri=>$dest,
	       -cookie=>$cookie);

=head2 C<cookie_login( I<$user>, I<$pass> )>

=over 4

=item Synopsis

Query the database to determine whether the provided password
correctly corresponds to the stored password for the given user ID.
If so, create the I<ScavAuth> cookie and return it.

=item Arguments

I<$user> is the desired user ID.

I<$pass> is the corresponding password.

=back

=cut

sub cookie_login {

  # Expect the following arguments
  my $user = $_[0];
  my $pass = $_[1];

=pod

Whitespace-strip the nickname.

=cut

  $user =~ s/^\s+//;
  $user =~ s/\s+$//;

=pod

Get the UID number and password from users database.  The DB
connection parameters are hardcoded in this routine.  If we do not get
exactly one tuple back, pass an error message to C<ReLogin()> and
return C<undef>.

=cut

  my $query = "select owner, password from users where nick = \'$user\'";
  my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
  my $result = $conn->exec($query);
  my $errorMessage = $conn->errorMessage;

  if ( $result->ntuples != 1 ) {
    ReLogin("<h2><center>
Nobody goes by the nickname $user -- try again.
</center></h2>
<P>QUERY: $query</P>
<P>$errorMessage</P>");
    return undef; }

=pod

If the password does not match the result from the database, pass an
error to C<ReLogin()> and return C<undef>.  Otherwise, create the
I<ScavAuth> cookie and return it.

Currently, the I<ScavAuth> cookie consists entirely of the UID number.
This is not even vaguely secure.

=cut

  my ( $owner, $password ) = $result->fetchrow;
  if ( $password ne $pass ) {
    ReLogin("<h2><center>
Incorrect password -- try again.
</center></h2>");
    return undef; }

  # Return a cookie if all is well
  $auth_cookie = cookie(-name=>'ScavAuth',
			-value=>$owner);

  return $auth_cookie;
}

=head2 C<ReLogin( I<$message> )>

=over 4

=item Synopsis

Open the template file F<relogin.html> and replace lines containing
the magic string, C<E<lt>RELOGINE<gt>>, with the supplied message.

Returns unconditionally on EOF.

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
}
