#!/usr/bin/perl

# Assign chosen item to the currently logged-in user

use Pg;
use CGI qw/:standard/;

do 'tables.pl';

$magic_tag = "<QUERY>";
$template = "query.html";

my $assign_uid = param('uid');
my $item = param('index');
my $unclaim = param('unclaim');
my $redir_target = param('redir');

# The usual security policy
my $auth = cookie(-name=>'ScavAuth');
my $uid = $auth;

$uid = $assign_uid if $auth == 1 && $assign_uid;
ReLogin("<h2>Maybe you should log in first.</h2>") unless $uid;

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

sub claim_result {

  my $output = "<P>Attempting to (un)claim item number $item for user $uid.</P>\n";

  # Database connection -- we need to check if owned
  # Get a connection to the database with permission to get users
  my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
  my $query = "SELECT owner from list where index = $item";
  my $result = $conn->exec($query);

  ( my $r_owner ) = $result->fetchrow;

  do { $output .= "<h2>You do not have permission to do this. Already claimed by $r_owner.</h2>\n"; 
       return $output; 
     } unless ( $r_owner == 0 ) || ( $r_owner == $uid ) || ( $auth == 1 );

  my $action = "claimed";
  if ( $unclaim ) { $uid = "null"; $action = "unclaimed"; }
  $query = "UPDATE list SET owner = \'$uid\' WHERE index = $item";
  $result = $conn->exec($query);

  do { $output .= "<h2>You have successfully $action item number $item</h2>\n";
       return $output;
     }
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
