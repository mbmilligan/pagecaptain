use HTML::TreeBuilder;
$tree=HTML::TreeBuilder->new;
$tree->parse_file($ARGV[0] || 'node2.html');
$list=$tree->look_down("_tag","ol");
my ( $buffer, $d, $s );

open OUT, $ARGV[1] || '>node2.txt';
foreach ($list->content_list) {
  $buffer = '';
  foreach ($_->content_list) {
    unless (ref $_) { $buffer .= $_; }
    elsif ($_->tag eq 'img') { $buffer .= $_->attr('alt'); }
    else { $buffer .= $_->as_text; }
  } continue {
    $buffer =~ s/\$.*?TM\}+\$/(TM)/g;
    ( $d, $s ) = $buffer =~ m/^(.*)\s*\[(.*)\]\s*$/;
  }
  print OUT $d . "\t" . $s . "\n\n";
}
