#!/usr/bin/perl

use CGI qw/:standard/;
use Pg;

my $nick = Sanitize(param('nick'));
my $name = Sanitize(param('name'));
my $address = Sanitize(param('address'));
my $phone = Sanitize(param('phone'));
my $email = Sanitize(param('email'));
my $contact = Sanitize(param('contact'));
my $password = Sanitize(param('password'));
my $backup = Sanitize(param('backup')); # Backup password, that is

my $edit_user = param('edit');
my $auth_user = cookie(-name=>'ScavAuth');
my $auth = 0;

$auth = 1 if $edit_user && ( $edit_user == $auth_user );
if ( $auth_user == 1 ) {
  $edit_user = $auth_user;
  $auth = 1;
}

# Connect to DB
$conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");

# User name taken?
$match = $conn->exec("select owner from users where nick = \'$nick\'");
ReDo("<h2><center>Nickname taken ... please try again.</center></h2>")
  unless ( $match->ntuples == 0 ) || $auth;

# Does he know his password?
ReDo("<h2><center>
Your passwords don't match ... please try again.
</center></h2>")
  unless $password eq $backup;

# Does he have a password?
ReDo("<h2><center>You really need a password.</center></h2>")
  unless $password;

# A few other things we want.
ReDo("<h2><center>Please supply the required information.</center></h2>")
  unless $nick && $name && ( $address || $phone || $email || $contact );

# We're good to go -- insert/edit user.
my $query;
if ( $auth ) {
$query = "UPDATE users ";
$query .= "SET ";
$query .= "nick = \'$nick\', " if $nick;
$query .= "name = \'$name\', ";
$query .= "address = \'$address\', ";
$query .= "phone = \'$phone\', ";
$query .= "email = \'$email\', ";
$query .= "contact = \'$contact\', ";
$query .= "password = \'$password\' ";
$query .= "WHERE owner = $edit_user" }
else {
$query = "INSERT into users ";
$query .= "( nick, name, address, phone, email, contact, password ) ";
$query .= "VALUES ( ";
$query .= "\'$nick\', ";
$query .= "\'$name\', ";
$query .= "\'$address\', ";
$query .= "\'$phone\', ";
$query .= "\'$email\', ";
$query .= "\'$contact\', ";
$query .= "\'$password\' ";
$query .= ")"; }

$result = $conn->exec($query);
$status = $conn->errorMessage;
$message = "<h2>Something went wrong. Error message follows. Tell Michael.</h2>
<P>DID: $query</P>
<P>GOT: $status</P>"
  unless $status;

$query = "SELECT nick, name, address, phone, email, contact ";
$query .= "FROM users WHERE nick = \'$nick\'";
$result = $conn->exec($query);
$status = $conn->errorMessage;
$message = "<h2>Something went wrong. Error message follows. Tell Michael.</h2>
<P>DID: $query</P>
<P>GOT: $status</P>"
  if $status;

( $nick, $name, $address, $phone, $email, $contact ) = $result->fetchrow;

UserResults( $edit_user );

$message .= <<EOF;
<h3><center>
Please confirm your information is correct. If it is not, please 
contact the <A href="mailto:mbmillig\@midway.uchicago.edu">web-guru</A>
to fix whatever you screwed up. He didn\'t have time to write a way for
you to do this yourself. Oh well.
</center></h3>
<table align="center">
  <tr align="left"><td>Nickname:</td><td>$nick</td></tr>
  <tr align="left"><td>Real Name:</td><td>$name</td></tr>
  <tr align="left"><td>Address:</td><td>$address</td></tr>
  <tr align="left"><td>Phone:</td><td>$phone</td></tr>
  <tr align="left"><td>Email:</td><td>$email</td></tr>
  <tr align="left"><td>Other:</td><td>$contact</td></tr>
</table>
<h3 align="center">Only fill out the information below to create another
user. If you see the correct information above, your user <B>has been
successfully created</B>. Thank you.</h3>
EOF

ReDo($message);

# This is where we end up, one way or another. It doesn't return. It
# simply spits out a canned html form with the given message inserted.
sub ReDo {

  my $magic_tag = "<MESSAGE>";
  my $source = "adduser.html";
  my $message = $_[0];
  
  print header;

  open SOURCE, $source;
  
  while (<SOURCE>) {
    if ( /$magic_tag/ ) { print $message; }
    else { print $_; }
  }

  exit 0;
}

# If we are editing a user's info, we go here.
sub UserResults {
  my $edit_user = shift;

  my $uri = "http://neutrino.homeip.net/scav/User.pl?uid=$edit_user";
  print redirect(-uri=>$uri);
  exit 0;
}


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
