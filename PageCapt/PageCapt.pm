use PageCapt::User;
use PageCapt::Web;
use PageCapt::DB;

#
# Administrator-configurable parameters follow
#

$PageCapt::DB::db_string = "dbname=scavhunt user=user password=password";

$PageCapt::Web::secret = "foo";
$PageCapt::Web::cookiename = "PCauth";

=head1 NAME

PageCapt - loader and configuration module for PageCapt system

=head1 DESCRIPTION

This is not even a real module.  All it does is pull in the real
PageCapt modules that we need, and define a few configuration
variables that each of them uses.

=cut
