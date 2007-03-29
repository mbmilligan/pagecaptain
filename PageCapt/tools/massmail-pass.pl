#!/usr/bin/perl

use PageCapt;

my $sendmail = "/usr/lib/sendmail -t";
my @uids = @ARGV ? @ARGV : PageCapt::DB::list_user_ids;

foreach $id (@uids) {
  my $user = PageCapt::User->new($id);
  my $message = message( $user->login,
			 $user->name,
			 $user->email,
			 $user->password );
  open (SENDMAIL, "|$sendmail") || die "Can't run sendmail!";
  print SENDMAIL $message;
  close SENDMAIL;
  print "Sent reminder for ".$user->name."\n";
}

sub message {
  my ($login, $name, $email, $password) = @_;

  return <<EOF;
To: $email
From: ScavHunt Website <mbmillig\@midway.uchicago.edu>
Subject: User/Password notice

Hi --

At some point in the past, you filled out the Deleuzean Potato
team survey under the name $name.

This message has been sent (automatically) to inform and/or remind
you of your current login name and password, so you can use all of
the cool features on our team's website.

Your login name is: $login
Your password is: $password

Thank you,
  An Anonymous Member of the
    Tech Turnip's Evil Technological Minions

EOF
}

