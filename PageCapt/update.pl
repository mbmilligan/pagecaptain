#!/usr/bin/perl

=head1 NAME

update.pl - a CGI program in the ScavCode PageCaptain app

=head1 DESCRIPTION

This CGI program provides the primary facility for altering data in the item
list, by setting fields in the database to the values provided in the CGI
parameters.  The fields describing the item itself (currently the index,
description, and scoring fields) cannot be modified via this, or any other,
interface.

On execution, the template (any file with an C<.html> extension) is loaded,
and various tag-formatted strings are replaced by generated values and status
information.  This script is called from the HTML controls in the templates
F<admin_edit.html>, F<annotate.html>, F<owner_edit.html>, and F<update.html>.
Currently, no script dynamically emits invocations of this script.

It is a serious bug that this script performs no authentication checking when
updating an item; it assumes that users will only call it via the controls
that have been provided to them, which are customized based upon their access
control status.  

This program uses C<CGI> and C<Pg>.

This program loads F<tables.pl>.

=head2 CGI Parameters

=over 4

=item I<source>

Required parameter.  Names the file to open as the template.  This can
currently be any string ending in C<html>, which is not especially secure.
Many of these parameters should be filtered through C<Sanitize()>, but
currently none are.

=item I<index>

Required parameter.  This is the index number of the item to be updated.
Failing to provide a value will produce an SQL syntax error instead of
something sensible to the user, though.  Note that non-numeric characters in
this field will be stripped out.

=item I<score>

Optional.  If provided, the I<score> field will be replaced with the provided
string.  Characters that would not appear in a decimal or fractional number
will be stripped out.

=item I<cat>

Optional.  If provided, this parameter contains a category named in the
I<%category> hash in F<tables.pl>.  The I<type> field will be set to the
corresponding value.  Note that providing an invalid value will result in
I<type> remaining unchanged.

=item I<status>

Optional. If provided, this parameter contains a status string from the
I<%status> hash in F<tables.pl>.  The I<status> database field will be set to
the corresponding value.  As before, an invalid value results in no change.

=item I<notes>

Optional.  The I<notes> database field will be appended with the contents of
this parameter, enclosed in an HTML E<lt>PE<gt> block.  Single quote
characters ("'") are escaped, but not safely.  This is a bug.

=back

=head2 Interpolated Tags

=over 4

=item C<E<lt>QUERYE<gt>>

Replaced by the string returned by C<updatelist()>, which contains an HTML
table displaying the new information for the updated item.

=item C<E<lt>IDXE<gt>>

Replaced by the value of the I<index> parameter.

=item C<E<lt>IDX_NEXTE<gt>>

Replaced by the value of the I<index> parameter plus 1.  Assumes a numeric 
value of I<index>.

=item C<E<lt>IDX_PREVE<gt>>

Replaced by the value of the I<index> parameter minus 1.  Also assumes that
I<index> is numeric.

=back

=cut

use CGI qw/:standard/;
use Pg;

do 'tables.pl';

=head1 IMPLEMENTATION

=head2 Main Body

Save the value of the I<source> parameter.  If this string does not end in
C<html>, die with an error message.  Print HTTP headers, open the specified
template file, and begin substituting tags as specified above.

=cut

my $magic_tag = "<QUERY>";
$source = param('source'); if ( $source !~ /html$/ ) { die "You fool!"; }

open SOURCE, $source;

print header;

while (<SOURCE>)
  { if ( /$magic_tag/ ) { updatelist() } else 
      { if ( /<IDX>/ ) { $idx = param('index'); s/<IDX>/$idx/; print $_; } 
	elsif ( /<IDX_NEXT>/ ) { $idx = param('index')+1; s/<IDX_NEXT>/$idx/; 
			      print $_; } 
	elsif ( /<IDX_PREV>/ ) { $idx = param('index')-1; s/<IDX_PREV>/$idx/; 
			      print $_; } 
	else {print $_; } } }

=head2 C<updatelist()>

=over 4

=item Synopsis

Perform the database updates specified by the parameters, and print to
the client an HTML table with the data for the updated item
(technically, we could produce a multi-row table, but this should not
ever happen.

=item Arguments

None.  This function requires only that the standard CGI functions have been
exported into this namespace.

=back

=cut

sub updatelist
  { $i = param('index');
    $i =~ s/[^0-9]//g;
    $score = param('score');
    $score =~ s/[^0-9.\/]//g;
    if ( $score eq "" ) { $s = ""; } else 
      { $s = "points = $score"; }
    $c = param('cat');
    $cat = $category{$c};
    if ( $cat eq "" ) { $c = ""; } else
      { $c = "type = $cat"; }
    $sta = param('status');
    $st = $status{$sta};
    if ( $st eq "" ) { $t = ""; } else
      { $t = "status = $st"; }
    $notes = param('notes');
    if ( $notes eq "" ) { $n = "" } else 
      { $notes =~ s/'/\\'/g;
	$n = qq!notes = notes || '<P>$notes</P>'!; }

=pod

This function begins by processing the CGI parameters (except I<source>) into
SQL statements.

I<index> is stripped of non-digit characters and saved in a variable I<$i>.

I<score> is stripped of all characters except 0-9, ".", and "/".  If the
result is not empty, save the string C<points = I<$score>>.

I<cat> is replaced with the value I<$category{$cat}> as defined in
F<tables.pl>.  If this value is not empty, save the string C<type = I<$cat>>.

I<status> becomes I<$status{$status}> using F<tables.pl> again.  If non-empty,
save C<status = I<$status>>.

If I<notes> is non-empty, replace every "'" with "\\'", and save the string
C<notes = notes || 'E<lt>PE<gt>$notesE<lt>/PE<gt>'>.

Set I<$cmd> to the I<score> string.  For each of the I<cat>, I<status>, and
I<notes> strings, append each to the I<$cmd> string if non-empty, prepended
with a comma (C<, >) if I<$cmd> is already non-empty.

The SQL query is then C<UPDATE list SET I<$cmd> WHERE index = I<$i>>.

=cut

    $cmd = $s;
    foreach ( ($c, $t, $n) ) 
      { if ( $_ ne "" && $cmd ne "" ) { $cmd = "$cmd, $_"; } else
	{ if ( $cmd eq "" ) { $cmd = $_; } } }
    $q = "UPDATE list SET $cmd WHERE index = $i";

    # This works. We don't need to keep printing the query.
    # print "$q<P>\n";
    $conn = Pg::connectdb("dbname=scavlist user=postgres password=timelord");
    $result = $conn->exec($q);

    my $error_status = $conn->errorMessage;
    my $debug = 0;
    print "<P>QUERY: $q</P>" if $error_status || $debug;
    print "<P>$error_status</P>" if $error_status;

    $result = $conn->exec("select * from list where index = $i order by index");
    $count = $result->ntuples;

=pod

Connect to the database (connection parameters are hardcoded here) and
execute the query.  If debugging is enabled, or if an error message is
returned from the database, print an informational message to the
client.

Retrieve all fields for the item modified from the database.  Note the
number of rows returned (should always be equal to 1).

Print a color code table to the client.  This code is inline, but
closely derived from the color code generator function 
L<getquery.pl/"C<color_code()>">.

=cut

    # Print a color code
    print "Color code: \n";
    print "<Table border=1>";
    foreach ( keys %status )
	{ $colstr = "";
	  if ( $statcol{$_} ne "" ) { $colstr = " bgcolor=\"$statcol{$_}\""; }
	  print "<TD$colstr>$_</TD>"; }
    print "</Table>\n<P>\n";

=pod

Print table and column header tags, including:

  <TH>Index<TH>Points<TH>Category<TH>Item<TH>Scoring<TH>Notes</TH>

Loop to generate table rows, using code basically cribbed from
L<getquery.pl/"C<gentable()>"> and some old code from F<testpg.pl>.

First construct two lists I<@stats> and I<@cats> such that the I<i>th
entry is the key from I<%status> and I<%category>, respectively, with
value I<i>.  Note that this is quite fragile now, since we accomplish
this by simply sorting the keys on their values.

For each row returned (again, should be exactly one): 

Assign each field of the row to a variable, using numeric field
positions with L<CGI/"getvalue">.  Use the above lists to map the
I<type> to a category name, and the I<status> to a color (via
I<%statcol> in F<tables.pl>).  Print out the appropriate C<tr> and
C<td> HTML tags to construct a table row from these values.

Print the closing table tag.

=cut

    print "<Table cellpadding=3 border=2 width=100%>
           <TR><TH>Index<TH>Points<TH>Category<TH>Item<TH>Scoring<TH>Notes</TH></TR>\n";

    @stats = sort { $status{$a} <=> $status{$b}; } keys %status;
    @cats = sort { $category{$a} <=> $category{$b}; } keys %category;

    for ( $i = 0; $i < $count; $i++ )
      { $r_index = $result->getvalue( $i, 0 );
	$r_score = $result->getvalue( $i, 1 );
	$r_type = $result->getvalue( $i, 2 );
	$r_status = $result->getvalue( $i, 3 );
	$r_desc = $result->getvalue( $i, 4 );
	$r_comm = $result->getvalue( $i, 5 );
	$r_notes = $result->getvalue( $i, 6 );

	$color = $statcol{$stats[$r_status]};
	$cat = $cats[$r_type];

	print "<tr bgcolor=\"$color\">";
	print "<td>$r_index</td>";
	print "<td>$r_score</td>";
	print "<td>$cat</td>";
	print "<td>$r_desc</td>";
	print "<td>$r_comm</td>";
	print "<td>$r_notes</td></tr>\n"; };
    
    print "</Table>\n"; }

=head2 C<Sanitize( $string )>

=over 4

=item Synopsis

Sanitize and return a string by using regular expressions to strip
leading and trailing whitespace, and escaping single quote characters
("'") not already preceeded by a backspace.  Much safer than
techniques used above.  This function is never called.

=item Arguments

I<$string> is the string to be sanitized.

=back

=cut

# This should strip out leading and trailing space, and escape any 
# single-quotes (but not unescape them).
sub Sanitize {

  my $string = $_[0];

  $string =~ s/^\s+//gm;
  $string =~ s/\s+$//gm;

  $string =~ s/^'/\\'/mg;
  $string =~ s/([^\\])'/$1\\'/g;

  return $string;
}
