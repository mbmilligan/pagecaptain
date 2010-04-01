#!/usr/bin/perl

my $mason_comp_root = undef;
my $mason_data_dir = '/usr/local/share/mason/data/';

# -maybe- use lib '/some/path'

use HTML::Mason::CGIHandler;
use PageCapt;

my $h = new HTML::Mason::CGIHandler
 (
  data_dir  => $mason_data_dir,
  comp_root => $mason_comp_root,
  allow_globals => [qw(%session $u $User)],
  error_mode => 'output'
 );

$h->handle_request;
