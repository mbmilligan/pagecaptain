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

In particular, many of the routines here deal with various hashing
operations (password generation, cookie signing, etc.), that can be
used by non-web interfaces as well.

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
  my %cookie = $cgi->cookie($cookiename);
  my $user = new PageCapt::User( $cookie{uid} );
  my $hash = _compose_hash( $user );

  $user->assert_validity;
  return $user if $hash eq $cookie{mac};
  return undef;
}

=head3 C<logout_cookie()>

Return a cookie that, when submitted to the client, will nullify any
previously existing login cookie.  This is accomplished by both
setting the value to null, and setting the expiration to a time in the
past.

=cut

sub logout_cookie {
  return CGI::cookie( -name  => $cookiename,
		      -value => '',
		      -expires => '-1d'
		    );
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

=head3 C<mail_password( [I<$user> [,...] ] )>

Send out a standard password reminder email.  If one or more I<$user>
parameters is provided, send email to those users only.  If no
parameters are provided, do a mass-mailing to all users in the system.

We return C<undef> in case of drastic error.

Based on the F<massmail-pass.pl> utility program.

=cut

sub mail_password {
  my @uids = @_;
  @uids = PageCapt::DB::list_user_ids unless @uids;
  foreach my $id (@uids) {
    my $u = PageCapt::User->new($id);
    my $login = $u->login;
    my $name = $u->name;
    my $email = $u->email;
    my $password = $u->password;
    my $message = eval qq{"$reminder_message"};

    open (SENDMAIL, "|$sendmail") || die "Can't run sendmail!";
    print SENDMAIL $message;
    close SENDMAIL;
  }
}

=head3 C<generate_password( [ I<$string>, [ I<$length> ] ] )>

Generate a random password of specified length.  If this length is not
provided, a default should be defined in the F<PageCapt.pm>
meta-module.  The I<$string> is required for generation to be
deterministic, as we will otherwise use some handy source of
randomness.  At most 27 characters will be returned (the length of a
base-64 encoded 160-bit digest).

=cut

sub generate_password {
  my $seed = shift || time();
  my $length = shift || $pass_length;
  my $hash = new Digest::SHA1;

  $hash->add($seed);
  $hash->add($secret);
  return substr( $hash->b64digest, 1, $length );
}

=head3 C<generate_addrcookie( $length )>

Generate a random email address cookie of specified length, up to 27
characters.  By default, 14 characters will be returned.

The data is derived from a BASE64 encoded hash, but this function
ensures that only characters valid in address cookies are returned.

=cut

sub generate_addrcookie {
  my $length = shift || 14;
  my $hash = new Digest::SHA1;
  $hash->add(rand());

  my $str = substr( $hash->b64digest, 1, $length );
  $str =~ tr{/+}{XY};
  return $str;
}

=head3 C<stash_addrcookie( $cookie, { parameter => value, ... } )>

Stores a hash-ref of parameters and values, constituting a session which
can be retrieved using the provided $cookie.  The hash contents will be
string concatenated with '=' and stored in the database.  Thus it is 
necessary that neither contain the '=' character, and it is probably better
if '\' and the single-quote are also avoided.  The cookie should be shorter
than the database varchar key width, currently 16 characters wide.

=cut

sub stash_addrcookie {
  my $cookie = shift || return undef;
  my $hashref = shift || return undef;
  return undef unless ref $hashref eq 'HASH';

  my @strings = map { $_ . '=' . $$hashref{$_} } keys %$hashref;
  return PageCapt::DB::set_parameter( $cookie, [ @strings ], undef, 'session' );
}

=head3 C<restore_addrcookie( $cookie )>

Returns the hash stored by C<stash_addrcookie()>.

=cut

sub restore_addrcookie {
  my $cookie = shift || return undef;
  my @strings = PageCapt::DB::get_parameter( $cookie, undef, undef, 'session' );
  my %pars;
  foreach my $pair (@strings) {
    my ($key, $val) = split(/=/, $pair, 2);
    $pars{$key} = $val;
  }
  return %pars;
}

=head3 C<destroy_addrcookie( $cookie )>

Remove a stored cookie session from the database.

=cut

sub destroy_addrcookie {
  my $cookie = shift || return undef;
  return PageCapt::DB::set_parameter( $cookie, [], undef, 'session' );
}

=head2 Spam Filter System

PageCaptain includes a basic spam-filtering system appropriate for scanning
many types of text stream.  It is configured via two variables:

I<$PageCapt::Web::spamwords> sets the location of a text file containing
one string per line.  The text string will be scanning against each string,
and the spam score incremented for each one found.  

I<$PageCapt::Web::hamwords> sets the location of a similar file containing
strings that decrement the spam score.

=head3 C<ratespam( I<$text> )>

Returns a numeric rating equal to the number of spam-associated tokens
found in I<$text>, less the number of non-spam tokens.  

Set I<$PageCapt::Web::spamstrings> to the empty list to force reloading
of the spamwords file.

=cut

our @spamstrings;
our @hamstrings;

sub ratespam {
  my $text = shift;
  my $score = 0;
  return 0 unless $spamwords;

  load_spamstrings() unless @spamstrings;
  study $text;

  for my $str (@spamstrings) {
      while ($text =~ m/$str/gi) { $score++; }
  }
  for my $str (@hamstrings) {
      while ($text =~ m/$str/gi) { $score--; }
  }

  return $score;
}

sub load_spamstrings {
  if ($PageCapt::Web::spamwords) {
    open SPAM, "<", $PageCapt::Web::spamwords ||
	do { $PageCapt::Web::spamwords = undef; return; };
    @spamstrings = <SPAM>; chomp @spamstrings;
    close SPAM;
    unless (@spamstrings) {
	do { $PageCapt::Web::spamwords = undef; return; }
    }
  }
  if ($PageCapt::Web::hamwords) {
    open SPAM, "<", $PageCapt::Web::hamwords || 
	do { $PageCapt::Web::hamwords = undef; return; };
    @hamstrings = <SPAM>; chomp @hamstrings;
    close SPAM;
    unless (@hamstrings) {
	do { $PageCapt::Web::hamwords = undef; return; }
    }
  }
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
  $hash->add($ENV{HTTP_X_FORWARDED_FOR} || $ENV{REMOTE_ADDR});
  $hash->add($secret);
  return $hash->b64digest;
}

1;
