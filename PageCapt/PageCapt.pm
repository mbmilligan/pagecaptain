use PageCapt::User;
use PageCapt::Web;
use PageCapt::DB;

#
# Administrator-configurable parameters follow
#

$PageCapt::DB::db_string = "dbname=scavhunt user=user password=password";

$PageCapt::Web::secret = "foo";
$PageCapt::Web::cookiename = "PCauth";
$PageCapt::Web::pass_length = 6;
$PageCapt::Web::sendmail = "/usr/lib/sendmail -t";
$PageCapt::Web::fromaddr = 'ScavHunt Website <mbmillig@midway.uchicago.edu>';
$PageCapt::Web::reminder_message = <<'END';
To: $email
From: $fromaddr
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

END

=head1 NAME

PageCapt - loader and configuration module for PageCapt system

=head1 DESCRIPTION

This is not even a real module.  All it does is pull in the real
PageCapt modules that we need, and define a few configuration
variables that each of them uses.

=cut
