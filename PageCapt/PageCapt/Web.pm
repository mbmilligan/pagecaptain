package PageCapt::Web;

#
#  Administrator-configurable parameters follow
#

my $secret = "foo";

=head1 NAME

PageCapt::Web - Utility functions for the PageCaptain web-app component

=head1 DESCRIPTION

This module provides utility functions that are commonly used by the
PageCaptain suite web-app personality.  This includes generating and verifying
cookies (we assume a CGI environment in this module).  Although the web site
is implemented in Mason, any Mason-specific code should go in Mason
components, not here.

=cut

use PageCapt::User;
use Digest::SHA1;

@ISA = qw(PageCapt);

=head1 ROUTINES

=head2 Cookie Functions

=head3 C<new_cookie( I<$User> )>

Hashes together user and client identifying information along with salt, and
returns a cookie string suitable for inclusion in HTTP headers.  The User
object will be checked for validity (in the authorization sense, see
L<PageCapt::User>); returns C<undef> on failure.

=cut

sub new_cookie {

}

=head3 C<extract_cookie( I<$cookie> )>

Extract and verify the information in the provided cookie string.  Returns a
PageCapt::User object on success, C<undef> on failure.

=cut

sub extract_cookie {

}
