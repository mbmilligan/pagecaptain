package PageCapt::User;

#
#  Admin-configurable parameters
#



=head1 NAME

PageCapt::User - class representing users in the PageCaptain system

=head1 DESCRIPTION

This class (not just module) implements a User in the PageCaptain system.
This includes interaction with the PageCapt database, although any actual
database transactions will be performed via C<PageCapt::DB> (see
L<PageCapt::DB>).

Note that this class generally prefers to fetch data from the DB instead of
storing it internally.  This is mostly because we usually have a DB connection
hanging around, so queries are effectively free.  Also, the DB is persistent,
whereas these objects usually are not, so why bother storing data in them.

=cut

use PageCapt::DB;

@ISA = qw(PageCapt);

=head1 CONSTRUCTORS

=head3 C<new( I<$uid> )>

Return a new User object with the given UID.  No check is done to assure that
this user exists.

=cut

sub new {
  my $self = shift;
  my $class = ref $self || $self;
  my $uid = shift;
  unless ($uid) {  # Just In Case we are called as blah::new($id)
    $uid = $class;
    $class = __PACKAGE__;
  }

  bless { data => { uid => $uid } }, $class;
}

=head3 C<blank()>

Return an empty User object, i.e. one with no properties.  These values should
be filled in by accessor functions prior to calling the C<commit> or C<create>
methods, or doing password validation with C<validate_password>.

=cut

sub blank {
  my $self = shift;
  my $class = ref $self || $self;
  bless { }, $class;
}

=head3 C<byname( I<$login> )>

A convenient wrapper constructor.  Create a new User object identified
only by a login name, ready for password validation.  As an added
bonus, this constructor leaves freshness undefined, so immediately
C<reload>-ing this object will let us fetch data by login name.

=cut

sub byname {
  my $self = shift || return undef;
  my $class = ref $self || $self;
  my $login = shift || return undef;
  my $new = $class->blank;
  $new->login( $login );
  $new->{fresh} = undef;
  return $new;
}

=head1 METHODS

=head2 Accessors

=head3 C<uid( [I<$uid>] )>

Return the UID for this object, if set.  With an argument, set the UID
instead.  If the UID is set to a different value than this object had
previously stored, any previously loaded data is discarded.

=cut

sub uid {
  my $self = shift || return undef;
  my $uid = shift;

  if ( defined $uid ) {
    if ( $uid != $self->{data}{uid} ) {
      $self->{data} = undef;
      $self->{fresh} = 0; }
    $self->{data}{uid} = $uid;
  }

  return $self->{data}{uid};
}

=head3 C<login( [I<$login>] )>

If set, return the login name for this object, C<reload()>-ing the
object if necessary to obtain this value.  With an argument, set this
value instead.

=cut

sub login {
  my $self = shift || return undef;
  my $login = shift;

  if ( defined $login )
    { $self->{data}{nick} = $login;
      $self->{fresh} = 1; }
  if ( (not defined $self->{data}{nick}) && $self->uid )
    { $self->reload; }
  return $self->{data}{nick};
}

=head3 C<name>, C<address>, C<phone>, C<email>, C<contact>, C<password> C<( [I<$data>] )>

These accessor methods fetch (no parameter) or set (with parameter)
the corresponding value in the object private data structure.  Once
set, these data can later be committed to the Users database.  If the
object has not already received any fresh data, this method will
attempt to load undefined values from the database.

If one of these methods has already been used to alter a value, this
object will be marked as containing "fresh" data, and will no longer
update from the database.  This means that you should read any values
you need from a user record, before altering values in the object.
However, the truly correct idiom for updating a user record is to
create a new object and fill in only those values you want to alter,
without referencing any other fields.  This way, those fields will
remain undefined, and will therefore not be touched by the database
operation.

Note that these functions are auto-generated from a table using
C<sprintf>-substitution and C<eval> to dynamically execute function
definitions.

=cut

my %accessors = 
  ( name     => 'name',
    address  => 'addr',
    phone    => 'phone',
    email    => 'email',
    contact  => 'other',
    password => 'pass'
  );

my $acc_func_string = <<'END_OF_FUNC';
sub %s {
  my $self = shift || return undef;
  my $data = shift;

  if ( defined $data ) 
    { $self->{data}{%s} = $data;
      $self->{fresh} = 1; }
  if ( (not defined $self->{data}{%s}) and $self->uid || $self->login )
    { $self->reload; }
  return $self->{data}{%s};
}
END_OF_FUNC

foreach my $func (keys %accessors) {
  eval sprintf( $acc_func_string, $func, ( $accessors{$func} ) x 3 );
}

=head2 Database

=head3 C<reload()>

If a UID or login name has been defined for this object, the User
database record for that key is retrieved and stored in the data field
of this object.  If retrieved by login name, the UID is updated.
There are few occasions when the front-end should call this method;
more often it will be invoked indirectly by an accessor method finding
that it is missing requested data.  Nothing is returned.

=cut

sub reload {
  my $self = shift || return undef;
  return undef unless $self->uid || $self->{data}{nick};
  return undef if $self->{fresh};

  if    ( $self->uid ) {
    $self->{data} = PageCapt::DB::get_user_by_uid( $self->uid ); }
  elsif ( $self->{data}{nick} ) {
    $self->{data} = PageCapt::DB::get_user_by_login( $self->{data}{nick} );
  }
  $self->{fresh} = 1;
}

=head3 C<commit()>

Update the database record corresponding to this user with the current
values of the data fields.  This operation is only successful for a
valid object.  On success, the data fields for this object are filled
in with all of the data for the updated user.  Returns C<undef> on
failure, or 0 if no such user exists or the database refuses the
updates (due to integrity constraints, for instance).

=cut

sub commit {
  my $self = shift || return undef;
  return undef unless $self->uid && $self->isvalid;
  my $data = PageCapt::DB::update_user( $self->uid, $self->{data} );
  if ( ref $data eq 'HASH' )
    { $self->{data} = $data;
      return 1; }
  else { return $data; }
}

=head3 C<create()>

Create a user with the login name specified by this object, and update
that user record with the data fields of this object.  On success,
returns true, and the object will be marked as valid and fresh.  It is
an error for the UID to be set before calling this method, as that
would imply that the corresponding user already exists in the
database.  It is also an error for the login name or password to not
be set.

Returns C<undef> on error, or 0 if the record cannot be created
(generally because the login name is taken).

=cut

sub create {
  my $self = shift || return undef;
  return undef if $self->uid;
  $self->{fresh} = 1;
  return undef unless $self->login && $self->password;

  my $uid = PageCapt::DB::new_user( $self->login );
  return $uid unless $uid;

  $self->{data}{uid} = $uid; # $self->uid( $uid ) would erase our unsaved data
  my $data = PageCapt::DB::update_user( $uid, $self->{data} );
  return $data unless $data;

  $self->{data} = $data;
  return 1;
}

=head2 Privilege

=head3 C<assert_validity()>

Declare to a User object that the current request has been validated as
originating with that User.  This method should only be called by modules that
provide their own authorization systems, since the resulting object will have
full permission to modify the User table entry for this User in the database.

=cut

sub assert_validity {
  my $self = shift;
  $self->{valid} = 1;
}

=head3 C<validate_password( I<$password> )>

Check that the provided password matches the one corresponding to this
user.  The mechanism by which this takes place is left undefined.  If
the password matches, the object is marked as valid.  A true value is
returned on success, 0 on failure, C<undef> on error.

The login name must already have been set via the C<login> method.

=cut

sub validate_password {
  my $self = shift || return undef;
  my $password = shift || return undef;
  return undef unless $self->login;
  my $data = PageCapt::DB::get_user_by_login( $self->login );
  if ( $data->{pass} eq $password )
    { $self->assert_validity;
      $self->{data} = $data; }
  else { $self->invalidate }
  return $self->isvalid;
}

=head3 C<clone_validity()>

Return a new User object with the same UID and validity status of this
one, but which has no data fields defined.  This is necessary to
create an object which, when C<commit>-ed, will have permission to do
a database commit (if this one does), but will not have predefined
data that would otherwise be reentered into the database, overwriting
any other changes that might have been made in the meanwhile.

=cut

sub clone_validity {
  my $self = shift || return undef;
  my $new = $self->new( $self->uid );
  $new->assert_validity if $self->isvalid;
  return $new;
}

=head3 C<isvalid()>

Return the validity status for this instance.  1 if valid, 0 for known
invalid, and undef for an instance for which no validity checking has
yet been done.

=cut

sub isvalid {
  my $self = shift;
  return $self->{valid};
}

=head3 C<invalidate()>

Remove validity status from this instance.

=cut

sub invalidate {
  my $self = shift;
  $self->{valid} = 0;
  return $self->{valid};
}

=head1 PRIVATE DATA

Like most Perl classes, the private instance data for this class is
kept in an anonymous hash (a blessed reference to which is the
instance object).  Code outside this class should never access the
following structure.

See L<PageCapt::DB/load_user_data()> for details on the structure of
the C<data> field.

  {
    fresh  => true if data has been loaded from the DB, or if current
              data supercedes the DB
    valid  => true if this object is certified as corresponding to the
              user making the current request
    data   => the object returned by PageCapt::DB::load_user_data()
  }

=cut

1;
