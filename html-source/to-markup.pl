#!/usr/bin/perl

# images

use strict;

sub loadfile {
  my $filename = shift;
  open(my $fh, '<:encoding(UTF-8)', $filename) or die "cannot open file: $!";
  my $o;
  while(<$fh>){ $o .= $_; }
  close($fh);
  return $o;
}

my $text;
while(<STDIN>){ $text .= $_; }

# newlines
$text =~ s/\r/ /g; # remove carriage returns
$text =~ s/\n/ /g;
$text =~ s/\s+/ /g;

$text =~ s/^\s+//gm; # remove space at beginning

# $text =~ s/^#/ #/gm; # no headers

$text =~ s/_Toc/Toc/g;
$text =~ s/_ftn/ftn/g;
$text =~ s/<a name="_Ref[^"]+"> *<\/a>//g;

$text =~ s/\*/\\\*/g;
$text =~ s/_/\\_/g;

# $text =~ s/<i>(.*?)<\/i>/_$1_/g; # italics

$text =~ s/style='[^']+' *//g;
$text =~ s/style="[^"]+" *//g;
$text =~ s/title=""//g;

$text =~ s/<([^>]{1,80}) +>/<$1>/g; # remove remaining space

$text =~ s/<br>\s*<p\s/<p /g;

# titles
foreach my $conv (1,2,3,4) {
$text =~ s/<p class='thh${conv}n?' *> *(.*?)<\/p> */do{
  my $t = $1;
  "\n\n".("#" x $conv)." " . $t . "\n\n";
}/egs;
}

# normal paragraphs
$text =~ s/<p class='thnorm(?:1|sp)?'> *(.*?)<\/p> */\n\n$1\n\n/gs;

# bibliography
$text =~ s/<p class='thbibl'> *(.*?)<\/p> */* $1\n/gs;


# blockquote
$text =~ s/<p class='thbq(?:1|1i)?'> *(.*?)<\/p> */do{
  my $t = $1;
  $t =~ s{[\n\s]+$}{};
  $t =~ s{\n}{\n> }g;
  # $t = '$'.$t if length($t)<80;
  "\n\n> ".$t."\n\n";
}/egs;

# toc
foreach my $conv (1,2,3,4) {
$text =~ s/<p class='MsoToc${conv}'> *(.*?)<\/p> */do{
  my $t = $1;
  ("  " x ($conv-1)) . "* " . $t . "\n";
}/egs;
}

# list
$text =~ s/<p class='thlist'> *(?:&#8211;)? *(.*?)<\/p> */* $1\n/g; 

# verse
$text =~ s/\s*<p class='thbqn'> *(.*?) *<\/p>/<br>$1/g;
$text =~ s/\s*<p class='thbqni'> *(.*?) *<\/p>/<br>&nbsp;&nbsp;&nbsp;$1/g;


# anchors - remove trailing space
$text =~ s/(<a name="[^"]+"><\/a>)\s+/$1/g;

$text =~ s/<br> */<br>/g;
$text =~ s/ *<br>/<br>/g;

# footnotes
my %footnotes;
$text =~ s/<div id='ftn(\d+)'> *<p class='MsoFootnoteText'> *(.*?) *<\/p> *<\/div>/do{
  $footnotes{$1} = $2;
  '';
}/gse;
$text .= "\n\n# Footnotes\n\n";
foreach my $ftn (sort {$a <=> $b} keys %footnotes){
  $text .= "* ".$footnotes{$ftn}."\n";
}

# extratext
$text =~ s/<div class="extratext"> *Please note that a more extensive introduction.*?<\/div>//;
$text =~ s/(<a name="postscript"><\/a>)<div class="extratext"> *<b>POSTSCRIPT<\/b>(.*?)<\/div>/# $1Postscript\n\n$2/;
$text =~ s/<div class="extratext">.*?<\/div>//g;

$text =~ s/(then)<br>(personifying)/$1 $2/;
$text =~ s/<span>caliban.<\/span>/CALIBAN./g;

# too many newlines
$text =~ s/\n{2,}/\n\n/g;

$text =~ s/\n(<br>)+/\n/g;
$text =~ s/<div> *<\/div>//g;

# merge blockquotes
$text =~ s/\n> ([^\n]{1,80})(?=\n)/\n> \$$1/gs; # mark short blockquotes with "> $"
$text =~ s/> \$([^\n]+)\n+(?=> \$)/> \$$1/gs; # remove newlines
$text =~ s/(?<!\n)> \$/<br>/g;
$text =~ s/\n> \$/\n> /g;

# non-ascii
# $text =~ s/\x{f6}/&ouml;/g;
# $text =~ s/\x{e1}/&aacute;/g;
# $text =~ s/\x{e9}/&eacute;/g;
# $text =~ s/\x{c9}/&Eacute;/g;
# $text =~ s/\x{fc}/&uuml;/g;
# $text =~ s/\x{f3}/&oacute;/g;
# $text =~ s/\x{ed}/&iacute;/g;
# $text =~ s/\x{e9}/&igrave;/g;
# $text =~ s/\x{bb}/&raquo;/g;
# $text =~ s/\x{ab}/&laquo;/g;

$text =~ s/\x{c3}\x{a9}/&eacute;/g;
$text =~ s/\x{c3}\x{a1}/&aacute;/g;
$text =~ s/\x{c3}\x{b6}/&ouml;/g;
$text =~ s/\x{c3}\x{89}/&Eacute;/g;
$text =~ s/\x{c3}\x{b3}/&oacute;/g;
$text =~ s/\x{c3}\x{ad}/&iacute;/g;
$text =~ s/\x{c3}\x{bc}/&uuml;/g;
$text =~ s/\x{c3}\x{a4}/&auml;/g;
$text =~ s/\x{c3}\x{b9}/&ugrave;/g;
$text =~ s/\x{c2}\x{bb}/&raquo;/g;
$text =~ s/\x{c2}\x{ab}/&laquo;/g;
$text =~ s/\x{c2}\x{ad}//g; # shy

# custom syntax
$text =~ s/\[sup\](.*?)\[\/sup\]/<sup>$1<\/sup>/g;
$text =~ s/\(\?nlinka\('browning.-en','([^']+)','([^']+)'\)\?\)/<a href="#$1">$2<\/a>/g;
$text =~ s/\[Q1\]/&ldquo;/g;
$text =~ s/\[Q2\]/&rdquo;/g;

# header
$text =~ s/^([^\n]+)/do{
  my $h = $1;
  $h =~ s{ *<\/?span> *}{}g;
  $h =~ s{ *<\/?p> *}{}g;
  my @hl = split(m{<br>}, $h);
  my $name = shift(@hl);
  my $title = shift(@hl);
  '# '.$title."\n\n".join('<br>', ($name,@hl));
}/sge;

for my $i (1,2){
$text =~ s/<span>(.*?)<\/span>/$1/g;
}

$text =~ s/[^\x{0a}\x{20}-\x{7f}]/do{
  print "(((".substr($`,-20)."|||".$&."|||".substr($',0,20).")))\n";
  $&;
}/sge;

print $text;
