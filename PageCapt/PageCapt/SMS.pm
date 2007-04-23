package PageCapt::SMS;
use PageCapt::Web;
use Email::Simple;
use Email::Send;
use Scalar::Util qw( blessed );

=head1 NAME

PageCapt::SMS - package providing SMS-over-email functions

=head1 DESCRIPTION

In this package we provide the information and functions necessary to
send and receive SMS messages, allowing PageCapt to interact with cell
phones in real time.  Since this is done via email, the calling
application must make arrangements to send and receive email on the
server system.

The package can either be used procedurally or via the class interface.

=head1 DATA

=head3 C<$email>

This package variable should be set to something sensible; otherwise
you're counting on the MTA to fill in a return path.  Generally
unnecessary if the module will only be used to send messages, though.

=cut

$email = "" unless $email;

=head3 C<%providers>

The C<%providers> dictionary encapsulates the email interfaces for
major mobile providers.  The structure is:

{ shortname => { fullname => Long provider name
	         email    => SMS gateway domain }
}

To send an SMS, prepend the 10-digit phone number to the domain.

Example: 9055556543@mmode.com

=cut

%providers = 
( 'ATT'      => { fullname => 'Former AT&T Wireless', email => '@mmode.com' },
  'Cingular' => { fullname => 'Cingular',  email => '@mobile.mycingular.com' },
  'Metrocall'=> { fullname => 'Metrocall', email => '@page.metrocall.com' },
  'Nextel'   => { fullname => 'Nextel',    email => '@messaging.nextel.com' },
  'Sprint'   => { fullname => 'Sprint PCS',email =>'@messaging.sprintpcs.com'},
  'TMobile'  => { fullname => 'T-Mobile',  email => '@tmomail.net' },
  'Verizon'  => { fullname => 'Verizon',   email => '@vtext.com' },
  'ALLTEL'   => { fullname => 'ALLTEL',    email => '@message.alltel.com' },
);

=head1 CONSTRUCTOR METHODS

=head3 C<newtext( $text )>

Takes an RFC2822 email message as a scalar, stores the message for
further processing, and returns an object.

=cut 

sub newtext {
  my $pkg = shift;
  my $msg = shift;
  my $self = bless { }, (ref $pkg || $pkg);
  $self->msg($msg);
  return $self;
}

=head3 C<newinput>

Reads an RFC2822 email message from STDIN, stores the message for
further processing, and returns an object.

=cut

sub newinput {
  my $pkg = shift;
  my $msg = join("", <STDIN>);
  $pkg->newtext($msg);
}

=head3 C<respondtoinput>

Reads an RFC2822 email message from STDIN, performs default
processing, send reply message(s) if applicable.  Returns object.

=cut

sub respondtoinput {
  my $pkg = shift;
  $self = $pkg->newinput;
  $self->makeresponse;
  $self->send;
  return $self;
}

=head3 C<newto( [ $dest, [ $msg ]] )>

Prepare a new message for sending, optionally given a destination
email address (not e.g. just the phone number!) and message body
(bodies), and return an object.  C<$dest> and C<$msg> may be either
scalar string values, or array-refs contains lists of bodies and
destinations.

=cut

sub newto {
  my ($pkg, $dest, $msg) = @_; 
  my $self = bless { }, (ref $pkg || $pkg);
  ref $dest ? $self->dests(@$dest) : $self->dests($dest);
  ref $msg ? $self->body(@$msg) : $self->body($msg);
  return $self;
}

=head3 C<sendnew( $dest, $msg )>

Create and send a new message with given destination and message body.

=cut

sub sendnew {
  my ($pkg, $dest, $msg) = @_;
  my $self = $pkg->newto($dest, $msg);
  $self->send;
  return $self;
}

=head1 INSTANCE METHODS

=head2 PROCESSORS

=head3 C<send>

Send the message(s) prepared in the object.  Returns true on success.
Not idempotent!

=cut

# Limit message bodies to 160 characters, including room for subject lines if present
sub splitmsgs {
  my $self = shift;
  my @msgs = $self->body;
  my @parts = ();
  my $subj = ($self->headers("Subject"))[0];
  my $len = 160;
  $len -= 4 + length($subj) if $subj;
  # Split into chunks no longer than $len
  foreach my $m (@msgs) {
    if (length($m) <= $len) { push @parts, $m; next; }
    foreach my $p ( split(/\n\n+/, $m) ) {
      if (length($p) <= $len) { push @parts, $p; next; }
      foreach my $l ( split(/\n/, $p) ) {
	if (length($l) <= $len) { push @parts, $l; next; }
	while (length($l) > $len) { push @parts, substr($l, 0, $len, ""); }
	push @parts, $l;
      }
    }
  }
  # Consolidate chunks where possible
  for my $i (0 .. $#parts-1) {
    if ( length($parts[$i]) + length($parts[$i+1]) <= $len)
      { $parts[$i+1] = $parts[$i] . $parts[$i+1]; $parts[$i] = ""; }
  }
  @parts = grep(length, @parts);
  $self->body(@parts);
}

sub send {
  my $self = shift;
  unless ( $self->headers("To") or $self->headers("Cc") or $self->headers("Bcc") )
    { return 0; }  # We need a destination to continue
  unless ( $self->body ) 
    { return 0; }  # We need a message body to continue
  unless ( $self->headers("From") )
    { $self->headers("From", $email); } # Default sender
  $self->splitmsgs;

  # No envelope, so can't bounce back at us
  my $mailer = Email::Send->new({ mailer => 'Sendmail', mailer_args => '-f <>' });
  my $email = $self->outbound_template;
  for my $msg ($self->body) {
    $email->body_set($msg);
    $mailer->send($email);
  }
}

=head3 C<makeresponse>

Parse the stored incoming email message, process any valid directives,
and prepare the outgoing message(s) for sending.

=head3 C<associate( $User )>

Associate a message exchange with a particular user by passing in a
PageCapt::User object.  If the user is validated the outgoing message
will include a token that will authenticate subsequent replies.

=head2 ACCESSORS

=head3 C<msg( [ $message ] )>

Get or set the text of the message to be processed.  

=cut

sub msg_set {
  my ( $self, $msg ) = @_;
  my $email = Email::Simple->new($msg);
  $self->{msgin} = $email;
  return $self->msg_get;
}

sub msg_get {
  my $self = shift;
  return $self->{msgin}->as_string
    if $self->{msgin};
}

sub msg {
  my ( $self, $msg ) = @_;
  if ($msg) { return $self->msg_set($msg); }
  else { return $self->msg_get; }
}

=head3 C<sender>

Get the sender email address from the message.  Actually just returns
the content of the From: header.

=cut

sub sender {
  my $self = shift;
  $self->{msgin}->header("From");
}

=head3 C<body( [ @bodies ] )>

Gets or sets the body text(s) for an outgoing message.  This is
complicated by the fact that output to SMS devices is limited to 160
characters per message, so longer messages must be split up.  During
sending when the final outputs are constructed any overlength messages
will be autosplit, but there are no guarantees that this will be
pretty (due to auth tokens, e.g., you don't even get the full 160
chars for the body, so err on the short side).  Better control is
achieved by passing in a list of intelligently segmented messages.

=cut

sub body {
  my ($self, @bodies) = @_;
  unless (@bodies) { return @{$self->{bodies}}; }
  $self->{bodies} = \@bodies;
}

=head3 C<headers( $field, [ $value, ... ] )>

Get or set the value of message header C<$field> in the outgoing
message.  Multiple values will result in multiple headers.  Returns a
list of all values of the given header otherwise.

=cut

sub outbound_temlate {
  my ($self, $email) = @_;
  if ($email and eval '$email->isa("Email::Simple")') { 
    $self->{msgout_templ} = $email;
  } elsif ( ! $self->{msgout_templ} ) { 
    $self->{msgout_templ} = Email::Simple->new(""); 
  }
  return $self->{msgout_templ};
}

sub headers {
  my ($self, $field, @values) = @_;
  my $out = $self->outbound_template;
  if (@values) { $out->header_set($field, @values); }
  return $out->header($field);
}

=head3 C<dests( @addrs )>

A wrapper around C<headers>, takes a list of addresses and sets the
To: field in the outgoing messages.

=cut

sub dests {
  my ($self, @addrs) = @_;
  $self->headers("To", @addrs);
}

=head1 PREFERENCES

This class uses the Tip table in the following ways:

=head3 _PCSMS_token

A preference with this key will be created to store the token
generated for a user.  Subsequent incoming messages can supply a UID
and this token to authenticate.  By default this token is only valid
for 24 hours, checked using C<get_parameter_raw>.

=head3 _PCSMS_email

This preference stores the last seen messaging email for this user.
It will be checked to validate tokens, and will be used as the
destination for automatic messages.

=cut
