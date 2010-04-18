# This is a SAMPLE local PageCaptain configuration
# Edit values to match your needs before using.

#
# Administrator-configurable parameters follow
#

# db_string tells the Pg module how to connect to your database
# If using local "ident" authentication, you need only the dbname
$PageCapt::DB::db_string = "dbname=scavhunt user=user password=password";

# tubers sets the initial superusers (the rest are added online)
%PageCapt::Web::tubers = ( mmilligan=>1 ); 

# secret should be a RANDOM string, used to encrypt cookies
$PageCapt::Web::secret = "foo";

# The return address of emails sent by the site -- maybe your site admin?
$PageCapt::Web::fromaddr = 'ScavHunt Website <nobody@example.com>';

# The leading component, if any, of the Pagecaptain URI path
# e.g. if the index page is example.com/pagecapt/index.mhtml
# then set base = "/pagecapt"
$PageCapt::Web::base = "";

# You may want to customize the welcome email.
# Including your team name or URL, for instance.
$PageCapt::Web::reminder_message = <<'END';
To: $email
From: $fromaddr
Subject: User/Password notice

Hi --

At some point in the past, you filled out theteam survey under the
name $name.

This message has been sent (automatically) to inform and/or remind
you of your current login name and password, so you can use all of
the cool features on our team's website.

Your login name is: $login
Your password is: $password

Thank you,
  An Anonymous Member of the
    Tech Turnip's Evil Technological Minions

END

# There is probably no need to change the following settings.
# 
# $PageCapt::Web::cookiename = "PCauth";
# $PageCapt::Web::pass_length = 6;
# $PageCapt::Web::spamwords = "spamwords.dat";
# $PageCapt::Web::hamwords = "hamwords.dat";
# $PageCapt::Web::sendmail = "/usr/lib/sendmail -t";

# You can change these if you don't like the existing selection of
# item categories or statuses.  These are stored as numeric values
# in the database, so if you edit this while there are items in your
# list it will have the effect of simply changing the labels shown
# on the web interface.
# 
# %PageCapt::DB::ItemTypeMap = ( RoadTrip   => 1,
# 			       Food	    => 2,
# 			       Craft	    => 3,
# 			       Performance  => 4,
# 			       Trivia	    => 5,
# 			       Olympics	    => 6,
# 			       Event	    => 7,
# 			       Thing        => 8,
# 			       AllStars     => 9,
# 			       FridayParty  => 10,
# 			       Showcase     => 11,
# 			       DryGames     => 12,
# 			       WetGames     => 13,
# 			       Abductee     => 14,
# 			     );
# %PageCapt::DB::ItemStatMap = ( Ongoing   => 1,
# 			       Done	   => 2,
# 			       Impossible  => 3,
# 			       HelpWanted  => 4
# 			     );


1;
