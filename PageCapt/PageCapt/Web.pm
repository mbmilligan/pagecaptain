package PageCapt::Web;

#
#  Administrator-configurable parameters follow
#

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
use URI;
use CGI;

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
  my $user = shift;
  return undef unless $user->isvalid;

  my $hash = _compose_hash( $user );
  return CGI::cookie( -name  => $cookiename,
		      -value => { uid => $user->uid,
				  mac => $hash }
		    );
}

=head3 C<extract_cookie( I<$cgi> )>

Extract and verify the information in the provided cookie string.
Returns a PageCapt::User object on success, C<undef> on failure.
I<$cgi> is a CGI object corresponding to the current request, from
which the session cookies may be extracted.

=cut

sub extract_cookie {
  my $cgi = shift;
  my $cookie = $cgi->cookie($cookiename);
  my $user = new PageCapt::User( $cookie->{uid} );
  my $hash = _compose_hash( $user );

  $user->assert_validity;
  return $user if $hash eq $cookie->{mac};
  return undef;
}

=head2 Other Functions

=head3 C<url( I<$path> [, I<$query> [, ...] ] )>

Construct a URL.  For now, we only handle relative URLs, but this
could change.  The currently supported parameters are I<$path>, the
(optionally relative) path to the desired resource, and I<$query>, a
hash-ref containing the desired keyword-value pairs for any query.

=cut

sub url {
  my $path = shift || return undef;
  my %query = %{shift @_};

  my $url = new URI;
  $url->path($path);
  $url->query_form(%query) if %query;
  return $url->canonical;
}

=head2 Internal Routines

=head3 C<_compose_hash( I<$user> )>

Compose the validation hash stored in our authentication cookies; this
is returned as a base64-encoded string.

=cut

sub _compose_hash {
  my $user = shift;
  my $hash = new Digest::SHA1;

  $hash->add($user->uid);
  $hash->add($ENV{REMOTE_ADDR});
  $hash->add($secret);
  return $hash->b64digest;
}
