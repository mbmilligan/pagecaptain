#!/usr/bin/perl

use PageCapt;

my %f = %u = $field = undef;
$/ = "";
while (<>) {
  chomp; 
  if ($field && /^[^ ]/ && ! /^Thank you/) 
    { $f{$field} .= "\n" . $_; next; }
  if (/^Survey results for (.*):/s) { $u{name} = $1; next; }
  if (/^ Email address: (.*)$/) { $u{email} = $1; next; }
  if (/^ Meal/) { s/Meal points/points/; }
  ( $field, $data ) = m/ ([a-zA-Z][a-z]+): (.*)$/s;
  $f{$field} = $data if $field;
}

my ( $login ) = $u{email} =~ m/\b(.*)@/;
my $user = byname PageCapt::User ($login);
$user->reload;
$user->login($login);
$user->name($u{name});
$user->email($u{email});

if ($user->uid) {
  $user->assert_validity;
  $user->commit; 
}
else {
  $user->password( PageCapt::Web::generate_password($u{name}) );
  print "Created User $login for " . $u{name}."\n" if $user->create;
}
PageCapt::DB::new_survey( $user, \%f );
print "Registered survey for " . $u{name} . "\n";

