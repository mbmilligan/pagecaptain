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

  bless { uid => $uid }, $class;
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

  $self->{uid} = $uid if defined $uid;
  if ( $self->{uid} != $self->{data}{uid} ) {
    $self->{data} = undef;
    $self->{fresh} = 0; }
  return $self->{uid};
}

=head3 C<login( [I<$login>] )>

If set, return the login name for this object, C<reload()>-ing the
object if necessary to obtain this value.  With an argument, set this
value instead.

=cut

sub login {
  my $self = shift || return undef;
  my $login = shift;

  $self->{data}{nick} = $login if defined $login;
  if ( (not defined $self->{data}{nick}) && $self->{uid} )
    { $self->reload; }
  return $self->{data}{nick};
}

=head3 C<name>, C<address>, C<phone>, C<email>, C<contact> C<( [I<$data>] )>

These accessor methods fetch (no parameter) or set (with parameter)
the corresponding value in the object private data structure.  Once
set, these data can later be committed to the Users database.

Note that these functions are auto-generated from a table using
C<sprintf>-substitution and C<eval> to dynamically execute function
definitions.

=cut

my %accessors = 
  ( name     => 'name',
    address  => 'addr',
    phone    => 'phone',
    email    => 'email',
    contact  => 'other'
  );

my $acc_func_string = <<'END_OF_FUNC';
sub %s {
  my $self = shift || return undef;
  my $data = shift;

  $self->{data}{%s} = $data if defined $data;
  if ( (not defined $self->{data}{%s}) && $self->{uid} )
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
  return undef unless $self->{uid} || $self->{data}{login};
  return undef if $self->{fresh};

  if    ( $self->{uid} ) {
    $self->{data} = PageCapt::DB::get_user_by_uid( $self->{uid} ); }
  elsif ( $self->{data}{login} ) {
    $self->{data} = PageCapt::DB::get_user_by_login( $self->{data}{login} );
    $self->{uid} = $self->{data}{uid}; }
  $self->{fresh} = 1;
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


=head3 C<isvalid()>

Return the validity status for this instance.  1 if valid, 0 for known
invalid, and undef for an instance for which no validity checking has
yet been done.

=cut

sub isvalid {
  my $self = shift;
  return $self->{valid};
}

=head1 PRIVATE DATA

Like most Perl classes, the private instance data for this class is
kept in an anonymous hash (a blessed reference to which is the
instance object).  Code outside this class should never access the
following structure.

See L<PageCapt::DB/load_user_data()> for details on the structure of
the C<data> field.

  { uid	   => primary UID value
    fresh  => true if data has been loaded from the DB, and not changed
    valid  => true if this object is certified as corresponding to the 
              user making the current request
    data   => the object returned by PageCapt::DB::load_user_data()
  }

=cut
