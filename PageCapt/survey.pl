#!/usr/bin/perl

use CGI qw/:standard/;

$sendmail = "/usr/lib/sendmail -t";

$name = param('name');
$major = param('major');
$talents = param('talents');
$nudity = param('nudity');
$home = param('home');
$points = param('points');
$age = param('age');
$schedule = param('schedule');

$to = "Cate Tolzmann <scavcat\@myrealbox.com>";
$subject = "Survey result for $name";
$from = "ScavHunt Survey <mbmillig\@midway.uchicago.edu>";

$body = <<EOF;
Survey results for $name: 

 Talents: $talents

 Major: $major

 Nudity: $nudity

 Home: $home

 Meal points: $points

 Age: $age

 Schedule: $schedule

Thank you.
EOF

open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!";

print SENDMAIL "To: $to \n";
print SENDMAIL "From: $from \n";
print SENDMAIL "Subject: $subject \n\n";
   
print SENDMAIL $body;

close(SENDMAIL);

print redirect('http://neutrino.homeip.net/scav/survey_thankyou.html');
