#!/usr/bin/perl

# Just a test at cookie setting. Call with uid=<number>

use CGI qw/:standard/;
use Pg;

my $uid = param('uid');
my $owner = cookie(-name=>'ScavAuth');

if ( $uid ) { $owner = $uid; }

print header;

print <<EOF;
<HTML>
<HEAD><TITLE>User Information</TITLE></HEAD>
<BODY>

EOF

print user_info( $owner );

print "</BODY></HTML>\n";

# Get and display as HTML information for given user
sub user_info {

  my $owner = shift;
  my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
  my $result = $conn->exec("select nick, name, address, phone, email, contact from users where owner = $owner");
  my @user = $result->fetchrow;

  my $html;

  unless ( @user ) {
    $html = "<H3>No user has UID $owner</H3>"; 
    unless ( $owner ) { $html .= "<P>And your cookie is null.</P>"; }
    return $html; }

  $html = <<EOF;
<P>Your cookie says you are user number $owner.</P>
<Table Border="1">
  <TR><TD>Login<TD>Name<TD>Address<TD>Phone \#<TD>E-mail<TD>Other Contact Info</TR>
  <TR><TD>$user[0]<TD>$user[1]<TD>$user[2]<TD>$user[3]<TD>$user[4]<TD>$user[5]</TR>
</Table>
EOF

  return $html;
}
