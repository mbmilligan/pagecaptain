use PageCapt;
use Digest::MD5 qw(md5_base64);

while (<>) {
  if (m/Survey results for (.*):/) { $name = $1; }
  if (m/Email address: (.*)/) { $email = $1; }
}

if (eof && $name) { 
  ($login) = $email =~ /([^@]+)@/; 
  $password = substr( md5_base64( $name . "x098np02e" ),
                      5, 6 );
  print "$name is $login at $email with password $password\n"; 
  $u = byname PageCapt::User($login);
  $u->name($name);
  $u->password($password);
  $result = $u->create;
  print (( $result == 0 ) ?
         ( "Could not create user; " . $u->login . " probably exists.\n" )
        : ( "Created " . $u->login . " for " . $u->name . "\n" ) );
}

