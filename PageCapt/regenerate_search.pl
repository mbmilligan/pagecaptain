#!/usr/bin/perl

# Create a dropdown menu of all the users, and insert it into search.html

use Pg;

my $magic_tag = "<MAGIC>";
my @source_list = qw/search.html admin_edit.html/;

foreach $file (@source_list)
{

my $source = $file . ".source";
my $dest = $file;

open IN, $source;
open OUT, ">$dest";

while ( <IN> )
{ if ( /$magic_tag/ )
  { print OUT &user_menu }
  else { print OUT $_; }
}

sub user_menu {

    my $output;
    my $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
    my $query = "SELECT owner, nick, name FROM users ORDER BY owner";
    my $result = $conn->exec($query);

    $output = qq|<SELECT name="uid">\n|;
    $output .= qq|<OPTION selected value="">Yourself</OPTION>\n|;
    $output .= qq|<OPTION selected value="nobody">All Unclaimed Items</OPTION>\n|;

    while ( ( my $owner, my $nick, my $name ) = $result->fetchrow )
    { my $string = $nick;
      $string = $name if $name;
      $output .= "<OPTION value=\"$owner\">$string</OPTION>\n";
  }
    
    $output .= "</SELECT>\n";
    
    return $output;
}

}
