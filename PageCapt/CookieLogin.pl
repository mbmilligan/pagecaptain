#!/usr/bin/perl

use CGI qw/:standard/;
use Pg;

$user = param('user');
$pass = param('pass');
$dest = param('dest');

# Sanitize anything going to DB
$user =~ s/[\']//g;

$cookie = cookie_login( $user, $pass );
exit unless $cookie;

# We're in. Proceed as directed.
print redirect(-uri=>$dest,
	       -cookie=>$cookie);

sub cookie_login {

  # Expect the following arguments
  my $user = $_[0];
  my $pass = $_[1];

  # Whitespace-strip the nickname
  $user =~ s/^\s+//;
  $user =~ s/\s+$//;

  # Get info from users database
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
