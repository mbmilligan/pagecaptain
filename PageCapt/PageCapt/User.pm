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
methods.

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
instead.

=cut

sub uid {
  my $self = shift;
  my $uid = shift;

  $self->{uid} = $uid if defined $uid;
  return $self->{uid};
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
