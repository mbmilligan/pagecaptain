package PageCapt::DB;

my %tip_classes = (
		   dump=>1,
		   survey=>2,
		   note=>3,
		   watch=>4,
		   config=>5,
		   pref=>6
		  );

my %schema =
  (
   GET_TIP_STMT	   => "SELECT time, date_trunc('minute',age('now',time)), extract('epoch' from time), creator, data, reference FROM Tip",
   TIP_CLASS_COND  => " WHERE class = '%u'",
   TIP_USED_COND   => " AND used = '%u'",
   TIP_UNUSED	   => " AND used = '0'",
   TIP_AGE_COND	   => " AND age('now',time) <= interval '%d day'",
   TIP_UID_COND	   => " AND creator = '%u'",
   TIP_REF_COND    => " AND reference = '%u'",
   TIP_TIME_COND   => " AND time = '%s'",
   TIP_KEY_COND	   => " AND key = '%s'",
   GET_TIP_SUFX	   => " ORDER BY time DESC",
   TIP_REF_ORD     => " ORDER by reference ASC",

   GET_NOTE_ITEMS  => "SELECT DISTINCT T.reference FROM Tip T",
   NOTE_WHO_SRC    => ", Tip W",
   NOTE_NOTE_CLASS => " WHERE T.class = '%u'",
   NOTE_WHO_CLASS  => " AND W.class = '%u'",
   NOTE_AGE_COND   => " AND T.time >= '%s'",
   NOTE_WHO_COND   => " AND W.creator = '%u' AND W.reference = T.reference",

   SRVY_FIELD_COND => " AND substring( data FROM '1' FOR position(':' IN data)-1 ) ILIKE '%s'",

   ADD_TIP_ANON_STMT => "INSERT INTO Tip (class, data) VALUES ('%u','%s')",
   ADD_TIP_WUID_STMT => "INSERT INTO Tip (class, creator, data) VALUES ('%u','%u','%s')",
   ADD_TIP_FULL_STMT => "INSERT INTO Tip (class, creator, reference, data) VALUES ('%u', '%u', '%u', '%s')",
   ADD_TIP_PAIR_STMT => "INSERT INTO Tip (class, creator, reference, key, data) " .
   	"VALUES (%s, %s, %s, '%s', '%s')",

   UPD_TIP_STMT => "UPDATE Tip SET",
   TIP_UID_SET => " creator = '%u'",
   TIP_UID_NSET=> " creator = NULL ",
   TIP_DAT_SET => " data = '%s'",
   TIP_USE_SET => " used = '%u'",
   TIP_REF_SET => " reference = '%u'",

   DEL_TIP_STMT => "DELETE FROM Tip",

   GET_USER_STMT  => "SELECT uid, login, name, address, phone, email, contact, password from Users",
   USER_UID_COND  => " WHERE uid = '%u'",
   USER_NICK_COND => " WHERE login = '%s'",
   USER_UID_ORD   => " ORDER BY uid",
   USER_NICK_ORD  => " ORDER BY login",
   USER_NAME_ORD  => " ORDER BY name",

   ADD_USER_STMT => "INSERT INTO Users ( login ) VALUES ( '%s' )",
   UPD_USER_STMT => "UPDATE Users SET",
   USER_NICK_SET => " login = '%s'",
   USER_NAME_SET => " name = '%s'",
   USER_ADDR_SET => " address = '%s'",
   USER_PHON_SET => " phone = '%s'",
   USER_MAIL_SET => " email = '%s'",
   USER_OTHR_SET => " contact = '%s'",
   USER_PASS_SET => " password = '%s'",

   GET_ITEM_STMT => "SELECT inum, points, type, status, description, scoring, cost, owner from List WHERE",
   UPD_ITEM_STMT => "UPDATE List SET %s WHERE",
   ITEM_NUM_COND  => " inum = '%u' ",
   ITEM_NUM_SET_C => " WHERE inum = '%u' ",
   ITEM_PNT_SET   => " points = '%f' ",
   ITEM_DESC_SET  => " description = '%s' ",
   ITEM_SCR_SET   => " scoring = '%s' ",
   ITEM_TYPE_COND => " type = '%u' ",
   ITEM_NTYP_COND => " type is null ",
   ITEM_STAT_COND => " status = '%u' ",
   ITEM_NSTA_COND => " status is null ",
   ITEM_COST_SET  => " cost = '%f' ",
   ITEM_OWN_COND  => " owner = '%u' ",
   ITEM_NOWN_COND => " owner is null ",
   ITEM_SRCH_COND => " description || scoring ~* '%s' ",
   ITEM_PNT_ORD   => " ORDER BY points DESC, inum ",
   ITEM_COST_ORD  => " ORDER BY cost DESC, inum ",
   ITEM_NUM_ORD   => " ORDER BY inum ",
   ADD_ITEM_STMT  => "INSERT INTO List ( inum ) VALUES ( '%u' )",

   RCNT_NOTE_STMT => "SELECT date_trunc('minute',age('now',T.time)), T.reference, T.creator, U.name, T.data FROM Tip T, Users U WHERE T.creator = U.uid AND T.class = '%u' ORDER BY time DESC LIMIT '%u' OFFSET '%u'",

   ITEM_OWN_SET_NULL => " owner = null ",

   LOGIC_AND => " AND ",
   LOGIC_OR  => " OR ",
   LOGIC_T   => " TRUE ",
   LOGIC_GRP => " ( %s ) ",
   SET_DELIM => ", "
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

  timestamp  => textual time-stamp
  age	     => textual age since creation
  epoch	     => seconds since UNIX epoch (for feeding to gmtime())
  uid	     => UID of user who created this tip, if defined
  content    => text of the tip

This function is really a convenience wrapper around C<get_user_dumptips()>.

=cut

sub get_dumptips {
  my $days = shift || 0;
  return get_user_dumptips( $days );
}

=head3 C<get_user_dumptips( [I<$days>], [I<$user>] )>

Identical to C<get_dumptips()> in return value.  If I<$user> is supplied, only
tips created by that user will be returned.  I<$user> can be a UID or a
PageCapt::User object (this only works if PageCapt::User is loaded, of course).
Specify I<$date> = 0 to get all tips, regardless of creation time.

=cut

sub get_user_dumptips {
  my $u;
  my $days = _clean_num(shift);
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u );
  my $stmt = $schema{GET_TIP_STMT};
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $tip_classes{dump} );
  $stmt .= $schema{TIP_UNUSED};
  $stmt .= sprintf( $schema{TIP_AGE_COND}, $days ) if $days;
  $stmt .= sprintf( $schema{TIP_UID_COND}, $user ) if $user;
  $stmt .= $schema{GET_TIP_SUFX};

  init();
  return _tip_to_hash( _runq($stmt) );
}

=head3 C<add_dumptip( I<$text>, [I<$user>] )>

Create a new Tip, dated now, with I<$user> as its creator if provided.
I<$user> can be either a UID or a PageCapt::User object.  Returns nothing.

=cut

sub add_dumptip {
  my $u;
  my $tip = _clean(shift);
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u );
  my $stmt = $user ?
    sprintf( $schema{ADD_TIP_WUID_STMT},
	     $tip_classes{dump}, $user, $tip ) :
    sprintf( $schema{ADD_TIP_ANON_STMT},
	     $tip_classes{dump}, $tip );

  init();
  _runq($stmt);
  return;
}

=head2 Survey Data

Survey data are free-form items of descriptive information associated
with our users, stored in the Tips table.  The data field is formatted
as "Field: content more content"; we will split on the first colon and
split these objects into a per-user structure like this:

  %user_survey =
  ( field1 => { time    => creation time (primary key)
                content => "content more content" }
    field2 => { ... }
    ...
  )

We are also interested in extracting one common field for all users
(e.g. a client wants to answer the question, WHO has volunteered meal
points).  In this case, we should extract records using a selection
clause along the lines of

  WHERE substring( data FROM '1' to position(':' in data)-1 ) == 'Field'

These results would be returned in a structure resembling the one
above, but keyed on UID or user login name, rather than field name.
Note that in both cases, the onus falls upon the requesting code to
keep track of what was requested, as the user or field name queried,
respectively, is not stored in the resulting data structure.

=head3 C<load_survey_user( I<$user> )>

Retrieve any existing survey results for the specified user.  I<$user>
can be either a C<PageCapt::User> object or a numeric UID.  The return
value is a hash structured like the one described above.

Note that all field names are lowercased, since the SQL query is
case-insensitive, but hash lookups are not.

=cut

sub load_survey_user {
  my $u;
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u ) || return undef;
  my $stmt = $schema{GET_TIP_STMT};
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $tip_classes{survey} );
  $stmt .= sprintf( $schema{TIP_UID_COND}, $user );

  my %survey;
  my @responses = _runq($stmt);
  foreach $row (@responses) {
    my ( $field, $data ) = split( /:/, $row->[4], 2 );
    $survey{lc($field)} = { time    => $row->[0],
			    content => $data };
  }
  return %survey;
}

=head3 C<new_survey( I<$user>, I<$survey> )>

Input a new set of survey responses into the database.  I<$user> is
defined as usual.  I<$survey> is a reference to a survey hash,
consisting simply of field-value pairs.  Returns true on success,
C<undef> on error.

This function reads in any existing survey responses for this user,
and if similarly named fields exist, it will attempt to update them.
For fields not corresponding to an existing entry in the database, a
new row is inserted instead.

=cut

sub new_survey {
  my ( $u, $stmt );
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u ) || return undef;
  my $new = shift || return undef;
  my %new = %$new;

  my %old = load_survey_user( $user );
  foreach my $field (keys %new) {
    my $dbfield = _clean_word(lc($field));
    next unless $dbfield;
    my $data = $dbfield . ":" . _clean($new{$field});
    if ($old{$dbfield}) {
      my @sets;
      $stmt = $schema{UPD_TIP_STMT};
      push @sets, sprintf( $schema{TIP_DAT_SET}, $data );
      $stmt .= join( $schema{SET_DELIM}, @sets ); 
      $stmt .= sprintf( $schema{TIP_CLASS_COND}, $tip_classes{survey} );
      $stmt .= sprintf( $schema{TIP_TIME_COND}, $old{$dbfield}{time} ); }
    else {
      $stmt = sprintf( $schema{ADD_TIP_WUID_STMT},
			  $tip_classes{survey}, $user, $data ); }
    _runcmd($stmt);
  }
}

=head2 Item Watchlist

Each user may define a list of items in which they have a declared interest,
which is then available to the front-end to display as desired.  These are
implemented as a class of Tip entries having only a creator and a reference
field.  Note that, while these functions will generally accept a
PageCapt::User object in place of a UID, they make no attempt to enforce
policy; it is the responsibility of the calling code to ensure that the
operation is permitted.

=head3 C<add_watchitem( I<$user>, I<$item> )>

I<$user> shall be the UID of the user (or a PageCapt::User object), and
I<$item> the number of the item, to be associated in a watchlist.  This
function will attempt to not create duplicate watch entries, but makes no
guarantees as to rigorously enforcing such a policy.  It is left undefined,
for now, whether or not it is an error to define a watch for a nonexistent
user, or item.

Returns undef on failure, >0 on success.

=cut

sub add_watchitem {
  my $u;
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u ) || return undef;
  my $item = _clean_num(shift) || return undef;
  my $stmt = sprintf( $schema{ADD_TIP_FULL_STMT}, $tip_classes{watch},
		      $user, $item, "" );
  init();
  return _runcmd($stmt);
}

=head3 C<get_watched_byuser( I<$user> )>

I<$user> a UID as before.  Returns a list in ascending order of item numbers
watched by that user, or undef on failure.  If the user is watching no items,
no error occurs, but the list will be empty.

=cut

sub get_watched_byuser {
  my $u;
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u ) || return undef;
  my $stmt = $schema{GET_TIP_STMT} . 
    sprintf( $schema{TIP_CLASS_COND}, $tip_classes{watch} ) .
    sprintf( $schema{TIP_UID_COND}, $user ) .
    $schema{TIP_REF_ORD};

  init();
  my @data = _runq($stmt);
  my @items;
  foreach $row (@data) { push @items, $row->[5]; }
  return @items;
}

=head3 C<get_watchers_byitem( I<$item> )>

I<$item> an item number as before.  Returns a list in undefined order of UIDs
corresponding to users watching the item, or undef on failure.  If no user is
watching the given item, the list will be empty, but no error occurs.

=cut

sub get_watchers_byitem {
  my $item = _clean_num(shift) || undef;
  my $stmt = $schema{GET_TIP_STMT} .
    sprintf( $schema{TIP_CLASS_COND}, $tip_classes{watch} ) .
    sprintf( $schema{TIP_REF_COND}, $item );
  
  init();
  my @data = _runq($stmt);
  my @watchers;
  foreach $row (@data) { push @watchers, $row->[3]; }
  return @watchers;
}

=head3 C<drop_watchitem( I<$user>, I<$item> )>

The parameters are the same as for other watchlist functions; any watchlist
entry for the given user and item is removed.  Returns >0 on success, undef
on failure, or 0 if no such watch was defined.

=cut

sub drop_watchitem {
  my $u;
  my $user = _clean_num( ref ($u = shift) ? $u->uid : $u ) || return undef;
  my $item = _clean_num(shift) || return undef;
  my $stmt = $schema{DEL_TIP_STMT} .
    sprintf( $schema{TIP_CLASS_COND}, $tip_classes{watch} ) .
    sprintf( $schema{TIP_UID_COND}, $user ) .
    sprintf( $schema{TIP_REF_COND}, $item );

  init();
  return _runcmd($stmt);
}

=head2 User Data

These routines know nothing about authentication or the current
request, since this module does not even import the PageCapt::User
class.  Therefore you should really avoid calling these routines
directly from front-end code, as invoking the appropriate User methods
will be more likely to do what you want.  However, using these may in
some cases be much more efficient than letting the User class do
certain tasks for you.

=head3 C<list_user_ids()>

Return a list containing the UIDs of every user in the system.  Use
the C<PageCapt::User> class or C<load_user_data()> to retrieve
additional information about these users.

=cut

sub list_user_ids {
  my @uids;
  my $stmt = $schema{GET_USER_STMT};
  my @results = _runq($stmt);

  foreach $row (@results) { push @uids, $row->[0]; }
  return @uids;
}

=head3 C<list_user_ulns( [C<{'uid'|'nick'|'name'}>] )>

Same as above, but a list of list-refs; each is an array consisting of
a uid-login name-real name triple.  If provided, the parameter
specifies which field to sort by.  The default is whatever random
order the database backend provides them in.

=cut

sub list_user_ulns {
  my $order = shift;
  my $stmt = $schema{GET_USER_STMT};
  my %map = ( uid=>'USER_UID_ORD', nick=>'USER_NICK_ORD', name=>'USER_NAME_ORD' );
  $stmt .= $schema{$map{$order}} if $order;
  my @results;
  foreach $row ( _runq($stmt) ) 
    { push @results, [ @$row[0..2] ]; }
  return @results;
}

=head3 C<load_user_data( I<$user>, [ C<{'uid'|'nick'}> ])>

Returns a structure containing the database record for the user specified by
I<$user>.  If the second parameter is C<'uid'>, this should be the UID number
for the user (this is the default), and if C<'nick'>, it should be the login
name.  Any other value is an error.

Note that in the following structure, the uid field corresponds to a primary
key of the database.  Therefore, simply checking that the uid field is defined
will establish whether or not the requested user record exists.

This function returns a hash-ref (both uid and login name should always be
unique) with the following structure:

  uid	 => numeric UID
  nick	 => login name
  name	 => full name
  addr	 => contact info: address
  phone	 => contact info: phone number
  email	 => contact info: email address
  other	 => contact info: other information
  pass	 => the password, doofus

Probably better if front-end code calls wrapper functions instead of calling
this directly.

=cut

sub load_user_data {
  my $user = lc(shift);
  my $which = shift || 'uid';

  my $sql = $schema{GET_USER_STMT};
  if    ( $which eq 'nick' ) {
    $sql .= sprintf( $schema{USER_NICK_COND}, _clean($user) ); }
  elsif ( $which eq 'uid' ) {
    $sql .= sprintf( $schema{USER_UID_COND}, _clean_num($user) ); }
  else { return undef; }

  my ( $row ) = _runq( $sql );
  return
    { uid => $row->[0],
      nick => $row->[1],
      name => $row->[2],
      addr => $row->[3],
      phone => $row->[4],
      email => $row->[5],
      other => $row->[6],
      pass => $row->[7]
    };
}

=head3 C<get_user_by_uid( I<$user> )>

A wrapper function, equivalent to C<load_user_data( $user, 'uid' )>.

=cut

sub get_user_by_uid {
  my $uid = shift;
  return load_user_data( $uid, 'uid' );
}

=head3 C<get_user_by_login( I<$login> )>

A wrapper function, equivalent to C<load_user_data( $user, 'nick' )>.

=cut

sub get_user_by_login {
  my $login = shift;
  return load_user_data( $login, 'nick' );
}

=head3 C<new_user( I<$login> )>

Insert a new user record into the database with the login name I<$login>.  As
the database is currently constructed, this should be no longer than 16
characters.  As a matter of policy, this should be a whitespace-free string of
alphanumeric characters, which will be checked in a case-insensitive manner.

Returns the UID number of the newly created user.  This record can then be
filled in with the corresponding data.  C<undef> is returned on error; as a
special case, the number 0 is returned if the insertion fails because the name
is taken already.

=cut

sub new_user {
  my $login = _clean_word(lc(shift)) || return undef;

  my $sql = $schema{GET_USER_STMT} . sprintf($schema{USER_NICK_COND}, $login);
  return 0 if _runq( $sql );

  $sql = sprintf( $schema{ADD_USER_STMT}, $login );
  _runq( $sql );
  my $user = load_user_data( $login, 'nick' );
  return $user->{uid};
}

=head3 C<update_user( I<$uid>, I<$user> )>

Alter the user record in the database for the user with UID I<$uid> with the
data in the I<$user> object (a hashref).  This object has the same structure
as that returned by the C<load_user_data()> function (see L</load_user_data>).
For each defined field (that corresponds to a field in the database) in the
I<$user> structure, the database will be updated with the supplied value, even
if that value is null.  Therefore, do not define fields that you wish to leave
unaltered, or else set them equal to the value returned by
C<load_user_data()>, if you are not worried about the possibility of
simultaneous updates taking place.

Returns the full user data structure for the altered user record, as returned
by C<load_user_data()>, or undef on error.  If no such user exists, no rows
will be modified.  In this case, 0 will be returned.

=cut

sub update_user {
  my $uid = shift || return undef;
  my $user = shift || return undef;
  return undef unless $uid == $user->{uid};

  my $stmt = $schema{UPD_USER_STMT};
  my @sets;
  if ( defined $user->{nick} )
    { push @sets, sprintf( $schema{USER_NICK_SET},
			   _clean_word(lc($user->{nick})) ); }
  if ( defined $user->{name} )
    { push @sets, sprintf( $schema{USER_NAME_SET}, _clean($user->{name}) ); }
  if ( defined $user->{addr} )
    { push @sets, sprintf( $schema{USER_ADDR_SET}, _clean($user->{addr}) ); }
  if ( defined $user->{phone} )
    { push @sets, sprintf( $schema{USER_PHON_SET}, _clean($user->{phone}) ); }
  if ( defined $user->{email} )
    { push @sets, sprintf( $schema{USER_MAIL_SET}, _clean($user->{email}) ); }
  if ( defined $user->{other} )
    { push @sets, sprintf( $schema{USER_OTHR_SET}, _clean($user->{other}) ); }
  if ( defined $user->{pass} )
    { push @sets, sprintf( $schema{USER_PASS_SET},
			   _clean_word($user->{pass}) ); }

  $stmt .= join $schema{SET_DELIM}, @sets;
  $stmt .= sprintf( $schema{USER_UID_COND}, $uid );
  my $mods = _runcmd($stmt);
  return 0 if $mods == 0;
  return load_user_data( $uid, 'uid' );
}

=head2 List Functions

These functions deal with items in the List.  A single item is
encapsulated in a hash with the following structure:

  ( number => item number
    points => a number, perhaps used for priority or expected score
    type   => short string tag used for categorization
    status => short string tag used for status coding
    cost   => a number, perhaps used to estimate difficulty or cost
    owner  => a number, the UID of claiming user, if any
    desc   => description of the item as provided by the Judges
    score  => how the item will be scored, according to the Judges
  )

Note that the various tags in this structure are represented
numerically in the database; mapping hashes defined in F<PageCapt.pm>
are used to translate between this internal representation and the
externally-visible tags.

The notes attached to items are treated like other Tip objects, except
that they have a defined I<creator> and I<reference> field.
Provisionally, they will be returned in the form used by
C<get_dumptips> with an additional field, I<item>, containing the
associated item number.  This will rarely be necessary, however, since
a note is generally associated with a particular item by virtue of an
explicit request parameter (i.e. get notes for item I<x>), or by
inclusion in a larger data structure.

=head3 C<load_list( [I<$parameters> ] )>

Return a list of hash-refs of the structure described above.  By
default, all items will be returned (this will be a large hunk of
data).  I<$parameters> is a hash-ref containing constraints to place
upon the search, defined below.  A general rule of thumb to this
structure is to recall, though, that it is essentially a template of
the item(s) being searched for, so the keys and possible values should
resemble those found in the Item structure.

  { number => retrieve item number; if set, all other parameters are ignored
    type   => return only items of this type
    status => return only items with this status
    owner  => return only items owned by this user
    desc   => regexp search the description and scoring fields for this
                (words will be split on whitespace and matched individually)
    sort   => { points | cost | number } sort on this field (default: number)
  }

In this object, the keys I<type>, I<status>, and I<owner> may take the
value C<none>, which will return only items for which the
corresponding property is null.

=cut

sub load_list {
  my $p = shift || { sort=>'number' };
  my %params = %$p;
  my $stmt = $schema{GET_ITEM_STMT};
  my %sortmap = ( points=>'ITEM_PNT_ORD', cost=>'ITEM_COST_ORD', number=>'ITEM_NUM_ORD' );
  my @cond;
  my $sort;

  $params{sort} = 'number' unless $params{sort};
  foreach (keys %params) {
    unless ( defined $params{$_} ) { next; }
    elsif ($_ eq 'number') { @cond = ( sprintf( $schema{ITEM_NUM_COND},
						_clean_num($params{$_}) ) );
			     last; }
    elsif ($_ eq 'type')   {
      if ( $params{$_} eq 'none' ) { push @cond, $schema{ITEM_NTYP_COND}; }
      else { push @cond, sprintf $schema{ITEM_TYPE_COND},
				 $ItemTypeMap{$params{$_}}; } }
    elsif ($_ eq 'status') {
      if ( $params{$_} eq 'none' ) { push @cond, $schema{ITEM_NSTA_COND}; }
      else { push @cond, sprintf $schema{ITEM_STAT_COND},
				 $ItemStatMap{$params{$_}}; } }
    elsif ($_ eq 'owner')  {
      if ( $params{$_} eq 'none' ) { push @cond, $schema{ITEM_NOWN_COND}; }
      else { push @cond, sprintf $schema{ITEM_OWN_COND},
	                         _clean_num($params{$_}); } }
    elsif ($_ eq 'desc')   { push @cond, sprintf $schema{ITEM_SRCH_COND},
						 _clean($params{$_}); }

    elsif ($_ eq 'sort') { $sort = $schema{$sortmap{$params{$_}}}; }
  }

  $stmt .= join( $schema{LOGIC_AND}, @cond ) || $schema{LOGIC_T};
  $stmt .= $sort if $sort;
  return _items_to_hash( _runq($stmt) );
}

sub _items_to_hash {
  my @list = @_;
  my @return;
  my %types = _invert_hash( %ItemTypeMap );
  my %status = _invert_hash( %ItemStatMap );

  foreach $row (@list) {
    push @return, { number => $row->[0],
		    points => $row->[1],
		    type   => $types{$row->[2]},
		    status => $status{$row->[3]},
		    cost   => $row->[6],
		    owner  => $row->[7],
		    desc   => $row->[4],
		    score  => $row->[5] };
  }
  return @return;
}

=head3 C<load_list_inums( I<@inums> )>

Returns identically to C<load_list()>.  I<@inums> is a list of item numbers
that will be returned as a list of hash-refs, sorted by item number.

=cut

sub load_list_inums {
  my @inums = @_ or return ();
  my @return;
  my $stmt = $schema{GET_ITEM_STMT};
  my @conds = map { sprintf($schema{ITEM_NUM_COND}, _clean_num($_)) } @inums;
  $stmt .= join( $schema{LOGIC_OR}, @conds ) . $schema{ITEM_NUM_ORD};
  return _items_to_hash( _runq($stmt) );
}

=head3 C<create_item( I<$inum> )>

I<$inum> is an integer corresponding to the item number to be added to the
List.  Returns the number of rows affected by the operation; this will be 1
on success, or 0 on failure, or undef on error.

The created item has no properties besides its number.  To insert a new item
into the List, follow this operation by a call to C<update_list()> with the
appropriate data.  

=cut

sub create_item {
  my $inum = shift || return undef;
  return undef unless _clean_num($inum) eq $inum;
  my $stmt = sprintf( $schema{ADD_ITEM_STMT}, $inum );
  return _runcmd($stmt);
}

=head3 C<update_list( I<$item> )>

I<$item> is a hash-ref table like the ones returned by C<load_list()>.  Any
defined parameters in this structure will be used as the new values for the
corresponding attributes in the database List object.  While we could
technically accept any set of constraints, we will avoid catastrophic errors
and require that the C<number> field be set, and use that field to choose
which item to update.  Thus, there is no way to change the number of an item
through this interface.  I have no idea why you would ever want to do such a
thing, anyway.  It used to be the case that the I<desc> and I<score> fields
could not be changed via this interface, since these are Judge-provided and
should be constant.  Now we honor these fields as well, but only if the
additional field I<input> is defined and set to a true value in the provided
hash, in an effort to prevent accidents.

I<owner> can take the value, C<none>, to set that field to null.

Returns the C<load_list()> structure for the modified item, or the number 0 if
no rows were modified (SQL error or no item with that number), or C<undef> on
error.

=cut

sub update_list {
  my $i = shift || return undef;
  my %item = %$i;
  return undef unless _clean_num($item{number});
  my @updates;

  foreach (keys %item) {
    if    ($_ eq 'number') { next; }
    elsif ($_ eq 'points') { push @updates, sprintf( $schema{ITEM_PNT_SET},
						     _clean_num($item{$_}) ); }
    elsif ($_ eq 'type')   { push @updates, sprintf( $schema{ITEM_TYPE_COND},
						     $ItemTypeMap{$item{$_}} ); }
    elsif ($_ eq 'status') { push @updates, sprintf( $schema{ITEM_STAT_COND},
						     $ItemStatMap{$item{$_}} ); }
    elsif ($_ eq 'cost')   { push @updates, sprintf( $schema{ITEM_COST_SET},
						     _clean_num($item{$_}) ); }
    elsif ($_ eq 'owner')  { push @updates, ($item{$_} eq 'none') ?
			       $schema{ITEM_OWN_SET_NULL} :
			       sprintf( $schema{ITEM_OWN_COND}, _clean_num($item{$_}) ); }
    elsif ($_ eq 'desc' and $item{input})
    	{ push @updates, sprintf( $schema{ITEM_DESC_SET}, _clean($item{$_}) ); }
    elsif ($_ eq 'score' and $item{input})
    	{ push @updates, sprintf( $schema{ITEM_SCR_SET}, _clean($item{$_}) ); }
  }
  $stmt = sprintf($schema{UPD_ITEM_STMT}, join( $schema{SET_DELIM}, @updates )) ||
    return (load_list({number => $item{number}}))[0];
  $stmt .= sprintf( $schema{ITEM_NUM_COND}, $item{number} );
  my $mod = _runcmd($stmt);
  return $mod unless $mod;
  return ( load_list( {number => $item{number}} ) )[0];
}

=head2 Notes Functions

Notes are very similar to dumpster tips, except that they have an associated
item in the database as well as a (optional) user.  The structure returned
will be identical, in fact, to that returned by C<get_dumptips()>.  Since one
only requests notes for a particular item at a time, there is no need to
specify it in the returned object.

=head3 C<get_item_notes( I<$item> [, I<$all> ] )>

Fetch the notes associated with a particular item.  The behavior and returned
list is otherwise identical to that of C<get_dumptips()>, except that we do
not specify an age cutoff.  I<$item> is just an item number.  An empty list
will be returned if this item does not exist.

If present and true, I<$all> indicates that the I<used> flag should be
disregarded when retrieving the item notes.  In this case, records with a true
value of I<used> will have an additional field, called I<used>, which will be
set to a true value as well.  Normally, no such field would be provided,
because only records with a false or null I<used> field would be returned.

=cut

sub get_item_notes {
  my $item = _clean_num(shift) || return undef;
  my $all = shift || undef;
  my $stmt = $schema{GET_TIP_STMT};
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $tip_classes{note} );
  $stmt .= $schema{TIP_UNUSED} unless $all;
  $stmt .= sprintf( $schema{TIP_REF_COND}, $item );
  $stmt .= $schema{GET_TIP_SUFX};

  my @result = _runq($stmt);
  my @notes;
  foreach $row (@result) {
    my $note = { timestamp => $$row[0],
		 age       => $$row[1],
		 epoch     => $$row[2],
		 uid       => $$row[3],
		 content   => $$row[4],
	       };
    $$note{used} = 1 if $$row[5];
    push @notes, $note;
  }
  return @notes;
}

=head3 C<get_new_noted_items( I<$time>, [ I<$uid> ] )>

Returns a list of item numbers to which notes have been added since I<$time>.
It should be noted that this is intended to be a timestamp from another
database operation.  While the underlying Postgres backend will accept other
string time specifiers, no guarantees are made about the backend timezone or
accepted formats.  In case of error, no results will be returned.

However, if I<$time> is defined and evaluates to false, the age test is
skipped.

If I<$uid> is specified and nonzero, restricts results to items watched by
I<$uid>.

=cut

sub get_new_noted_items {
  my $time = _clean(shift);
  my $uid = _clean_num(shift);

  my $stmt = $schema{GET_NOTE_ITEMS};
  $stmt .= sprintf( $schema{NOTE_WHO_SRC}, $uid ) if $uid;
  $stmt .= sprintf( $schema{NOTE_NOTE_CLASS}, $tip_classes{note} );
  $stmt .= sprintf( $schema{NOTE_WHO_CLASS}, $tip_classes{watch} ) if $uid;
  $stmt .= sprintf( $schema{NOTE_AGE_COND}, $time ) if $time;
  $stmt .= sprintf( $schema{NOTE_WHO_COND}, $uid ) if $uid;
  return map { $_->[0] } _runq($stmt);
}

=head3 C<get_site_recent_notes( I<$count>, [ I<$skip>, I<$class> ] )>

Returns comments recently posted on the site to all items.

I<$count> is the number of items to return.  I<$skip> is the number of items
to skip, allowing one to increment through the chronological list of notes.

I<$class> is the Tip class to search.  It defaults to C<note>.

Return format is a list of hash-refs containing:

  ( age  => string representation of elapsed time since note was posted
    item => number of the item to which the note was posted
    uid  => UID of the posting user
    name => Full name of the posting user
    text => text of the posted noted
  )

=cut

sub get_site_recent_notes {
  my $count = _clean_num(shift) || return ();
  my $skip = _clean_num(shift) || 0;
  my $class = shift;

  $class = $tip_classes{$class} || $tip_classes{note};
  my $stmt = sprintf( $schema{RCNT_NOTE_STMT},
		      $class, $count, $skip );
  my @row = _runq($stmt);
  my @return;
  for (@row) {
    push @return, { age  => $$_[0],
		    item => $$_[1],
		    uid  => $$_[2],
		    name => $$_[3],
		    text => $$_[4] };
  }
  return @return;
}

=head3 C<add_note( I<$text>, I<$item>, [I<$user>] )>

Attach a new note to an item.  I<$text> is a free-form string that will be
stored verbatim, and I<$item> is the number of the item with which to
associate the note.  If provided, I<$user> can be either a UID number or a
PageCapt::User object, and will be recorded as the creator of this note.

Returns true on success, C<undef> on failure.

=cut

sub add_note {
  my $note = shift || return undef;
  my $item = shift || return undef;
  my $user = (ref $_[0]) ? $_[0]->uid : shift;
  my $stmt = sprintf( $schema{ADD_TIP_FULL_STMT},
		      $tip_classes{note},
		      _clean_num($user),
		      _clean_num($item),
		      _clean($note) );
  my $mod = _runq($stmt);
  return $mod if $mod;
  return 1;
}

=head3 C<expire_note( I<$timestamp> )>

Set the I<used> flag in the note with the specified I<timestamp>, as
returned by C<get_item_notes()>, causing it to not appear by default
in the list of notes returned by C<get_item_notes()>.

Return true on success, C<undef> on failure.

=cut

sub expire_note {
  my $time = shift || return undef;
  my $stmt = $schema{UPD_TIP_SET};
  $stmt .= sprintf( $schema{TIP_USE_SET}, 1 );
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $tip_classes{note} );
  $stmt .= sprintf( $schema{TIP_TIME_COND}, _clean($time) );
  return _runcmd($stmt);
}

=head2 Parameter Storage

The Tip table has the ability to store generic key-value data pairs; this fact
is used here to store configuration parameters which make it possible to manage
some aspects of the system through an interactive interface.

Keys are stored in a C<varchar(16)>, which implies a length limitation.  By policy,
they should match C<[A-Za-z0-9]>; that is, they should be usable as Perl symbols,
for instance.  (Not that they ever are, at this point.  But it ensures we can make
a simple mapping between parameter keys and variable names.)

Global parameters are assigned a different class than per-user parameters.  By
convention, the first are referred to as "configurations," and the latter as
"preferences."  It follows that configuration values should never have an associated
UID, but preferences must always have one.

Parameters are multivalued (imagine an access control list, for instance).
The representation in the Tip table will be as multiple items with the same key
and, for preferences, the same UID.  An advantage is that we need not fuss
around with updating records by their timestamp; we simply add and delete
records.  Therefore, functions that fetch parameter values will return lists.
It is possible to store parameter data either by supplying a list, or by
providing specific values to be added or removed from the collection of values
for the corresponding key.

=head3 C<get_parameter( I<$key>, [ I<$uid>, I<$scalar>, I<$class> ] )>

Read a configuration value from the database.  Returns a list of all values
found.  There is no natural ordering.

By default, fetech the global configuration I<$key>.  If I<$uid> is set, fetch
the preference value I<$key> for that user.  If I<$scalar> is set and the
returned list would have zero or one element, the result is given as undefined
or a scalar, respectively.

If I<$class> is set, search the specified class instead of C<config> or C<pref>.
For instance, this will be applicable when we reimplement surveys as a key-value
structure analogous to preferences.

This is essentially a wrapper around C<get_parameter_raw()>.

=cut

sub get_parameter {
  my $key = _clean_word(shift);
  my $uid = _clean_num(shift);
  my $scalar = shift;
  my $class = shift;

  my @results = map { $_->{content} } get_parameter_raw($key, $uid, $class);
  if ( $scalar and $#results < 1 ) { $#results + 1 ? return $results[0] : return undef; }
  else { return @results; }
}

=head3 C<get_parameter_raw( I<$key>, [ I<$uid>, I<$class> ] )>

Does the work of C<get_parameter()> documented above.  Returns a list of
hash-refs as documented in C<get_dumptips()> as produced by C<_tip_to_hash()>.

=cut

sub get_parameter_raw {
  my $key = _clean_word(shift);
  my $uid = _clean_num(shift);
  my $class = shift;

  return undef unless $key;
  my $stmt = $schema{GET_TIP_STMT};
  unless ($tip_classes{$class}) {
    $class = $uid ? $tip_classes{pref} : $tip_classes{config}; }
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $class );
  $stmt .= sprintf( $schema{TIP_UID_COND}, $uid ) if $uid;
  $stmt .= sprintf( $schema{TIP_KEY_COND}, $key );
  return _tip_to_hash( _runq($stmt) );
}

=head3 C<add_parameter( I<$key>, I<$values>, [ I<$uid>, I<$class> ] )>

Add new key-value pairs to the database.  Returns the number of rows inserted,
or undef on error.

By default, the global configuration I<$key> will be altered, but if I<$uid> is
supplied, a preference corresponding to the user with that numeric ID will be
inserted instead.  No check is made to see if such a user exists, but the default
database schema includes a constraint that requires existence.  Thus specifying
a nonexistent I<$uid> will normally return as an error.

I<$values> is a list-ref containing the values to be stored.  Each value in the
referenced list will become half of a new key-value pair, and will thus be among
the values populating the list returned by C<get_parameter()>.  If I<$values>
points to the empty list, this function is a noop.

If I<$class> is provided, it will override the standard class selection logic
(global configuration, or preference is a I<$uid> is provided).  This might be
useful to the survey functions if they are reimplemented as preference-like
objects, but top-level code probably shouldn't do this.

=cut

sub add_parameter {
  my $key = _clean_word(shift) || return undef;
  my $vals = shift; return undef unless ref($vals) eq 'ARRAY';
  my $uid = _clean_num(shift);
  my $class = shift;

  unless ($tip_classes{$class}) {
    $class = $uid ? $tip_classes{pref} : $tip_classes{config}; }

  my $rows = 0;
  for (@$vals) {
    my $stmt = sprintf( $schema{ADD_TIP_PAIR_STMT}, $class,
		        $uid ? $uid : 'NULL', 'NULL', $key, $_ );
    my $tuples = _runcmd($stmt) or return undef;
    $rows += $tuples;
  }
  return $rows;
}

=head3 C<set_parameter( I<$key>, I<$values>, [ I<$uid>, I<$class> ] )>

Replace a configuration value with the supplied values.  Returns identically to
C<add_parameter()>.

I<$values> is a list-ref containing the values to be stored.  Any
preexisting values will be discarded, and each element in I<$values> will become
a key-value pair.  (If I<$values> points to an empty list, all values will be
discarded, and no further action taken.)

After performing the deletion, this function calls C<add_parameter()>, and thus
the functionality is identical.  This function wraps the operation in a
transaction to ensure that the previous values are preserved in the event of an
error, which is assumed to be the condition where C<add_parameter()> returns a
different number than the number of values passed to it.

=cut

sub set_parameter {
  my @args = @_;
  my $key = _clean_word($args[0]) || return undef;
  my $values = $args[1];
  my $uid = _clean_num($args[2]);
  my $class = $args[3];

  unless ($tip_classes{$class}) {
    $class = $uid ? $tip_classes{pref} : $tip_classes{config}; }
  _runcmd('BEGIN');
  my $stmt = $schema{DEL_TIP_STMT};
  $stmt .= sprintf( $schema{TIP_CLASS_COND}, $class );
  $stmt .= sprintf( $schema{TIP_UID_COND}, $uid ) if $uid;
  $stmt .= sprintf( $schema{TIP_KEY_COND}, $key );
  _runcmd($stmt);
  if ((my $ret = add_parameter(@args)) == ($#{$values} + 1)) {
    _runcmd('COMMIT'); return $ret;
  } else { _runcmd('ABORT'); return undef; }
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
  init();
  my $result = $connection->exec($sql);
  while ( my @temp = $result->fetchrow ) {
    push @results, \@temp;
  }
  return @results;
}

=head3 C<_runcmd( I<$sql> )>

Run the provided SQL string as in C<_runq()>.  This function is intended for
commands instead of queries, and thus the return value consists of the number
of rows affected by the command.

=cut

sub _runcmd {
  my $sql = shift;
  init();
  my $result = $connection->exec($sql);
  return $result->cmdTuples;
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

=head3 C<_clean_word( I<$string> )>

Strips the supplied string of non alphanumeric characters.  All
punctuation is removed, although what we are really interested in is
stripping '_' and '%' characters that would interfere with the C<LIKE>
SQL operator.  We allow '-' characters to live, for now.

=cut

sub _clean_word {
  my $string = shift;
  $string =~ s/[^0-9a-zA-Z-]//g;
  return $string;
}

=head3 C<_invert_hash( I<%hash> )>

I don't why Perl doesn't make this easier, but here is a utility
funtion to switch the keys and values in a hash table.  Returns the
inverted object.  Obviously, this operation is only reversible if the
values in the I<%hash> are unique.  If you pass

  ( a => 1,
    b => 1 )

then we cannot define whether I<$inverted{1}> will be C<'a'> or
C<'b'>.  So avoid doing that if you need reversibility.

=cut

sub _invert_hash {
  my %hash = @_;
  my %return;
  foreach (keys %hash) { $return{$hash{$_}} = $_; }
  return %return;
}

=head3 C<_tip_to_hash( I<@data> )>

C<@data> is the raw result list returned by C<_runq> in response to a
request for Tip data.  Returns a list of hash-refs in the format described
for C<get_dumptips()>.

=cut

sub _tip_to_hash {
  my @data = @_;
  my @result;
  foreach my $row (@data) {
    push @result, { timestamp	=> $row->[0],
		    age		=> $row->[1],
		    epoch	=> $row->[2],
		    uid		=> $row->[3],
		    content	=> $row->[4] };
  }
  return @result;
}

1;
