package PageCapt::DB;

#
# Administrator-configurable parameters follow
#

my $db_string = "dbname=scavhunt user=user password=password";

my %tip_classes = (
		   dump=>1,
		  );

my %schema =
  (
   GET_TIP_STMT =>
     sprintf("SELECT time, extract('epoch' from time), creator, data FROM Tip" .
	     " WHERE class = '%u' AND used = '0'", $tip_classes{dump} ),
   TIP_AGE_COND => " AND age(time) <= interval '%d day'",
   TIP_UID_COND => " AND creator = '%u'",
   GET_TIP_SUFX => " ORDER BY time DESC",

   ADD_TIP_ANON_STMT =>
     sprintf("INSERT INTO Tip (class, data) VALUES ('%u','%%s')", $tip_classes{dump})
  );

=head1 NAME

PageCapt::DB - Unified opaque database access for the PageCaptain

=head1 DESCRIPTION

This module provides accessor functions that hide the underlying database, and
in particular hide the details of SQL query construction, from the front-end
code.  Thus, software using this module can organize its logic in terms of
user and item properties, instead of a rigidly-defined table of fields.
Moreover, the database backend can be changed without harming the front-end
code.

There are three basic classes of database object right now:

=over 4

=item * Item

Items on the scavHunt list.  They have an array of descriptive properties,
mostly determined by the judges, but several mutable properties keep track of
the interaction between an item and the efforts of our team.

=item * User

Each team member (ideally) will have an associated user object that mostly
contains assorted contact information.  The real utility of these objects is
to provide a foreign key with which to tag Item objects to establish ownership
and assignment roles.

=item * Tip

An amorphous blob of user-supplied data that may be associated with various
things.  Classes of Tip include "Dumpster Dive Tips", Item comments, and
possibly others.

=back

For now, this module requires Postgres and the C<Pg> module, because I want
features that do not work in MySQL, which would be the other easy option.
Specifically, I want functional referential integrety checks, and I want
sub-selects that work.  Some day, perhaps I will code MySQL-compliant logic
for this module, but it is not needed right now.

=cut

use Pg;

@ISA = qw/PageCapt/;

my $connection;

=head1 ROUTINES

=head3 C<init()>

Initialize this module.  This includes (re-)establishing the database
connection kept in a private variable in this module.  This routine is
idempotent, so it should be called whenever the database is going to be used,
although most methods in this package will do this on their own as well.

=cut

sub init {
  return 1 if $connection && $connection->status == Pg::PGRES_CONNECTION_OK;
  $connection = Pg::connectdb($db_string);
  return 0 unless $connection->status == Pg::PGRES_CONNECTION_OK;
}

=head2 (Dumpster-Diving) Tips

=head3 C<get_dumptips( [I<$days>] )>

Return the current list of dumpster-diving tips.  If supplied, only tips
created less than I<$days> days ago will be returned.  The default is 3 days.

This function returns a list containing a newest-first ordered list of tip
objects.  Each of these is a hash-ref containing the following structure:

  timestamp => textual time-stamp
  epoch     => seconds since UNIX epoch (for feeding to gmtime())
  uid       => UID of user who created this tip, if defined
  content   => text of the tip

This function is really a convenience wrapper around C<get_user_dumptips()>.

=cut

sub get_dumptips {
  my $days = shift || 0;
  return get_user_dumptips( $days );
}

=head3 C<get_user_dumptips( [I<$days>], [I<$user>] )>

Identical to C<get_dumptips()> in return value.  If I<$user> is supplied, only
tips created by that user will be returned.  I<$user> can be a UID or a
PageCapt::User object (this is not implemented yet).  Specify I<$date> = 0 to
get all tips, regardless of creation time.

=cut

sub get_user_dumptips {
  my $days = _clean_num(shift);
  my $user = _clean_num(shift);
  my $stmt = $schema{GET_TIP_STMT};
  $stmt .= sprintf( $schema{TIP_AGE_COND}, $days ) if $days;
  $stmt .= sprintf( $schema{TIP_UID_COND}, $user ) if $user;
  $stmt .= $schema{GET_TIP_SUFX};

  init();
  my @data = _runq($stmt);
  my @result;
  foreach $row (@data) {
    push @result, { timestamp  => $row->[0],
		    epoch      => $row->[1],
		    uid	       => $row->[2],
		    content    => $row->[3] };
  }
  return @result;
}

=head3 C<add_dumptip( I<$text>, [I<$user>] )>

Create a new Tip, dated now, with I<$user> as its creator if provided.
When implemented, I<$user> can be either a UID or a PageCapt::User
object, but for now it does nothing.  Returns nothing.

=cut

sub add_dumptip {
  my $tip = _clean(shift);
  my $user = shift;  # ignored for now
  my $stmt = sprintf( $schema{ADD_TIP_ANON_STMT}, $tip );

  init();
  _runq($stmt);
  return;
}

=head2 Internal Functions

=head3 C<_runq( I<$sql> )>

Run the provided SQL string on the database connection.  A small utility
function that means I will not have to rewrite a dozen functions if I decide
to use DBI instead.  Return a list containing list-refs corresponding to the
returned tuples.

=cut

sub _runq {
  my $sql = shift;
  my @results;
  my $result = $connection->exec($sql);
  while ( my @temp = $result->fetchrow ) {
    push @results, \@temp;
  }
  return @results;
}

=head3 C<_dberror()>

Check various status indicators for the db connection.  If all is
well, returns C<undef>, otherwise the text of an error message or
status code will be returned.

=cut

sub _dberror {
  if ($connection->status == Pg::PGRES_CONNECTION_BAD) {
    return $connection->errorMessage;
  }
}

=head3 C<_clean( I<$sql> )>

Intelligently escape single quote characters (" ' ") so that
user-supplied input cannot break out of quotes in SQL statements.  We
also check for a final unescaped backslash and escape it.  Returns the
sanitized statement.  I *think* this is idempotent, but I have not
proved it to be so.

=cut

sub _clean {
  my $sql = shift;
  $sql =~ s/([^\\]|^)'/$1\\'/g;
  $sql =~ s/([^\\]|^)\\$/\\\\/;
  return $sql;
}

=head3 C<_clean_num( I<$number> )>

Strips the supplied statement of all non-numeric characters (0-9, +,
-, e, .) but makes no attempt to syntactically assure that the
returned value is a valid numeric expression.  Be warned.

=cut

sub _clean_num {
  my $num = shift;
  $num =~ s/[^-+.e0-9]//g;
  return $num;
}

1;
