use HTML::TreeBuilder;
$tree=HTML::TreeBuilder->new;
$tree->parse_file($ARGV[0] || 'node2.html');
$list=$tree->look_down("_tag","ol");
my ( $buffer, $d, $s, $p, $num );

open OUT, $ARGV[1] || '>node2.txt';
foreach ($list->content_list) {
  $buffer = '';
  foreach ($_->content_list) {
    unless (ref $_) { $buffer .= $_; }
    elsif ($_->tag eq 'img') { 
      my $latex = $_->attr('alt');
      $latex =~ s/\\([^a-zA-Z0-9])/$1/g;
      $latex =~ s/\$([a-zA-Z ]+)\$/<$1>/g;
      $buffer .= $latex; }
    else { $buffer .= $_->as_text; }
  }; 
  $buffer =~ s/\$.*?TM\}+\$/(TM)/g;
  ( $d, undef, $s ) = $buffer =~ m/^(.*?)\s*(\[(.*)\])?\s*$/;
  ( $p ) = sprintf( '%f', $s =~ m|([0-9./ ]+)| );
  $num++;
  my @ary = ( $num, $p, 'null', 'null', ($d || 'null'), ($s || 'null'), 'null', 'null' );
  print OUT join("\t", @ary), "\n";
}
