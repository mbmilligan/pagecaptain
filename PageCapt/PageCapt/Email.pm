package PageCapt::Email;
use PageCapt;
use base Email::MIME;

=head1 NAME

PageCapt::Email - package subclassing Email::MIME for PageCaptain

=head1 DESCRIPTION

In this package we subclass Email::MIME to get some commonly
needed behaviors, such as automatic de-MIMEing, snipping of
T-Mobile reply quoting, and address cookie extraction.

=cut

=head1 CONSTRUCTORS

=head3 C<blank()>

Returns a new PageCapt::Email object with no content.

=cut

sub blank {
  my $self = shift || undef;
  my $msg = <<ENDMSG;
To:
Subject:


ENDMSG
  return $self->SUPER::new($msg);
}

=head1 METHODS

Refer to the methods of Email::Simple and Email::MIME for additional
methods.  This class adds the following:

=head3 C<body_stripped()>

Returns the body of the email message, extracted from MIME multipart
encoding if necessary, and with any trailing quoted text removed.

Quoting can come in many forms.  At present only the quoting added
for T-Mobile SMS emails is removed.  Other forms will be added as
they cause problems.

=cut

sub body_stripped {
	my $self = shift;
  	my $ct = $self->content_type;
  	my $body = "";
  	if ($ct =~ m{text/plain}) {
	    $body = $self->body;
  	} else {
  		foreach ($self->parts) {
	    	$body = $_->body if $_->content_type =~ m{text/plain};
	    }
  	}
  	$body =~ s/^------.*//ms if $self->header('from') =~ /\@tmomail\.net/;
  	return $body;
}

=head3 C<addr_cookie( [$string] )>

Most reply-aware emails from PageCaptain will have a "cookie" added to
the return address, to aid in figuring out what the message is in reply
to.  This is because we can't predict what aspects of the outgoing
message will reliably be preserved, and possibly also to authenticate
messages claiming to be from particular users.

With a parameter, the given string is added to the message's sender,
and the modified object is returned. 

Without a parameter, the cookie (if any) is extracted and returned. 
On error, returns C<undef>.  In particular, this will occur if the 
message has no From: header, or if the cookie contains characters not 
allowed in an email address.

=cut

sub addr_cookie {
	my $self = shift || return undef;
	my $cookie = shift;
	my $from = $self->header('from');
	return undef unless $from;
	if ($cookie) {
		$from =~ s/\@/-${cookie}@/;
		$self->header_set('from', $from);
		return $self;
	} else {
		( $cookie ) = $from =~ m/-([^-@]*)@/g;
		return $cookie;
	}
}

=head3 C<addr_cookie_clear()>

Removes any cookie found on the From: header.  Returns the modified
object on success, undef on error.

Be careful about email addresses that might contain dashes.  We cannot
tell the difference between a cookie and the last word of a hyphenated
email local part.  Obviously, this also means that it is not safe to
use the dash character in a cookie string.

=cut

sub addr_cookie_clear {
	my $self = shift || return undef;
	my $from = $self->header('from') || return undef;
	$from =~ s{-([^-@]*)@}{@};
	$self->header_set('from',$from);
	return $self;
}

=head3 C<send()>

Delivers the message to the local mailer system.  There is considerable
variation in mailer system interfaces, so we going to try for a lowest
common demoninator sendmail-based system.  However, be aware that this
will only have been tested on Exim.

The message recipients will be computed by the mailer from the contents
of the To:, Cc:, etc. headers, so be sure to fill those in as needed.  If
the From: header is filled, we will try to override the mailer's default
sender field, but it is up to your system administrator to ensure that
the mailer daemon will let you do this.

=cut

sub send {
  my $self = shift || return undef;
  my $from = $self->header('from') || undef;
  my @fargs = ();
  if ($from) {
    @fargs = ( "-f", $from );
  }
  my $cmd = "/usr/lib/sendmail";
  my $oldsigpipe = $SIG{PIPE};
  my $pid = open(SENDMAIL, "|-", $cmd, @fargs, "-t");
  $SIG{PIPE} = 'IGNORE';
  print SENDMAIL $self->as_string;
  close SENDMAIL;
  $SIG{PIPE} = $oldsigpipe;
}


1;
