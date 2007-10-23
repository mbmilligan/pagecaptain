#!/usr/bin/perl 
#

use PageCapt;

my @opts = grep(/^-/, @ARGV);
my @args = grep(!/^-/, @ARGV);
for (@opts) { 
  m/^-([a-z])$/ && eval "\$opt_$1 = 1";
}

my $n = shift @args;
if ( not $n =~ m/^\d+(-\d+)?$/ ) { print <<EOF;
$0: view spam in Usemod wiki keep file
Usage: $0 [opts] <r> File.kp
	-l  enable link evaluation reporting
	-w  enable word frequency reporting
	r = integer revision number or range (n-m) to display
	
EOF
exit;
}
@ARGV = @args;

my $range = 0;
my ($low, $high);
if ( $n =~ m/-/ ) {
  $range = 1;
  ($low, $high) = ($n =~ m/(\d+)-(\d+)/);
}

sub revtest { 
  my $rev = shift;
  if ($range) { return ( ($rev==$low) .. ($rev==$high) ); }
  else { return ($rev == $n); }
}

$/ = chr(0xb3)."1"; 

my %r = ();
my %d = ();
my %t = ();

while (<>) {
  %r = split(chr(0xb3)."2");
  if( revtest($r{revision}) ) { 
    %d = split(chr(0xb3)."3", $r{data});
    $t{$r{revision}} = $d{text};
  } 
}

$/="\n";
for my $i (sort(keys(%t))) {
  print $t{$i}, "\n\n";
  print "Rev $i Spam total: ",PageCapt::Web::ratespam($t{$i}),"\n\n";

  # Optional reporting modules follow
  
  if ($opt_l) { 
    my ($l, $n);
    pos($t{$i}) = 0;
    while($t{$i} =~ m{\G(.*?)(<a.+?</a>)}cg) {
      $l += length($2);
      $n += length($1);
      print $1, " is ", length($1), " bytes\n", $2, " is ", length($2), " bytes\n";
    }
    $t{$i} =~ m{\G(.*)$};
    $n += length($1);
    print $1, " is ", length($1), " bytes\n\n";
    print "$l bytes of links\n"; 
    print "$n bytes outside links\n"; 
    printf("Entry is %.1f%% link text\n", 100*$l/($l+$n));
  }
  
  if ($opt_w) {
    my %l;
    pos($t{$i}) = 0;
    while($t{$i} =~ m{([a-z0-9]{3,})}ig) { 
      $l{lc($1)} += 1;
    }
    my @s = sort { $l{$a} <=> $l{$b} } keys %l;
    my $w = length($l{$s[$#s]});
    foreach (@s) {
      printf("%${w}d\t%s\n", $l{$_}, $_);
    }
  }
}
