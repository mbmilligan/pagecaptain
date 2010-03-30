use PageCapt::User;
use PageCapt::Web;
use PageCapt::DB;
use PageCapt::Email;

#
# Administrator-configurable parameters follow
#

$PageCapt::DB::db_string = "dbname=scavhunt user=user password=password";
%PageCapt::DB::ItemTypeMap = ( RoadTrip	    => 1,
			       Food	    => 2,
			       Craft	    => 3,
			       Performance  => 4,
			       Trivia	    => 5,
			       Olympics	    => 6,
			       Event	    => 7,
			       Thing        => 8,
			       AllStars     => 9,
			       FridayParty  => 10,
			       Showcase     => 11,
			       DryGames     => 12,
			       WetGames     => 13,
			       Abductee     => 14,
			     );
%PageCapt::DB::ItemStatMap = ( Ongoing	   => 1,
			       Done	   => 2,
			       Impossible  => 3,
			       HelpWanted  => 4
			     );

%PageCapt::Web::tubers = ( mmilligan=>1 ); 

INIT {
  for my $u (PageCapt::DB::get_parameter('tubers')) {
    $PageCapt::Web::tubers{$u} = 1;
  }
}

$PageCapt::Email::domain = "unrealcity.homeip.net";
$PageCapt::Email::sms_localpart = "fist.sms";

$PageCapt::Web::secret = "foo";
$PageCapt::Web::cookiename = "PCauth";
$PageCapt::Web::pass_length = 6;
$PageCapt::Web::spamwords = "spamwords.dat";
$PageCapt::Web::hamwords = "hamwords.dat";
$PageCapt::Web::sendmail = "/usr/lib/sendmail -t";
$PageCapt::Web::fromaddr = 'ScavHunt Website <mmilligan@astro.umn.edu>';
$PageCapt::Web::base = "";
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

do 'PageCapt-local.pm';

=head1 NAME

PageCapt - loader and configuration module for PageCapt system

=head1 DESCRIPTION

This is not even a real module.  All it does is pull in the real
PageCapt modules that we need, and define a few configuration
variables that each of them uses.

=cut

