#!/usr/bin/speedy
use HTML::Mason::CGIHandler;
use PageCapt;

my $h = new HTML::Mason::CGIHandler
 (
  data_dir  => '/usr/local/share/mason/data/',
  allow_globals => [qw(%session $u $User)],
 );

$h->handle_request;
