package PageCapt::DB;

#
# Administrator-configurable parameters follow
#

my $db_string = "dbname=scavhunt user=user password=password";

@ISA = qw/PageCapt/;

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

