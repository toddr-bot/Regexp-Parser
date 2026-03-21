use strict;
use warnings;

use Test::More tests => 28;
use Regexp::Parser;

my $r = Regexp::Parser->new;

# Basic parsing
ok( $r->regex('(?{1})'), 'parse (?{1})' );
ok( $r->regex('(??{1})'), 'parse (??{1})' );

# Nested braces
ok( $r->regex('(?{ if (1) { 2 } })'), 'parse code with nested braces' );
ok( $r->regex('(??{ { a => 1 } })'), 'parse logical with nested braces' );
ok( $r->regex('(?{ { { deeply() } } })'), 'parse deeply nested braces' );

# Escaped content
ok( $r->regex('(?{ "foo\\nbar" })'), 'parse code with escape sequences' );

# Round-trip tests
my @roundtrip = (
  '(?{1})',
  '(??{1})',
  '(?{ if (1) { 2 } })',
  '(??{ { a => 1 } })',
  '(?{ "foo\\nbar" })',
);

for my $rx (@roundtrip) {
  $r->regex($rx);
  is( $r->visual, $rx, "round-trip: $rx" );
}

# code() accessor on eval nodes
{
  $r->regex('(?{my $x = 42})');
  my $w = $r->walker;
  my ($node, $depth) = $w->();
  is( $node->type, 'eval', 'eval node type' );
  is( $node->family, 'assertion', 'eval node family' );
  is( $node->code, 'my $x = 42', 'eval code() accessor' );
  is( $node->data, 'my $x = 42', 'eval data() accessor' );
  is( $node->visual, '(?{my $x = 42})', 'eval visual()' );
  ok( $node->isa('Regexp::Parser::eval'), 'eval isa check' );
}

# code() accessor on logical nodes
{
  $r->regex('(??{$patterns{$type}})');
  my $w = $r->walker;
  my ($node, $depth) = $w->();
  is( $node->type, 'logical', 'logical node type' );
  is( $node->family, 'assertion', 'logical node family' );
  is( $node->code, '$patterns{$type}', 'logical code() accessor' );
  is( $node->data, '$patterns{$type}', 'logical data() accessor' );
  is( $node->visual, '(??{$patterns{$type}})', 'logical visual()' );
  ok( $node->isa('Regexp::Parser::logical'), 'logical isa check' );
}

# Code blocks in conditionals
{
  $r->regex('(?(?{check()})yes|no)');
  my $w = $r->walker;
  my ($n1, $d1) = $w->();
  is( $n1->type, 'ifthen', 'conditional with code block' );
  my ($n2, $d2) = $w->();
  is( $n2->type, 'eval', 'code block as condition' );
  is( $n2->code, 'check()', 'condition code() accessor' );
}

# Unbalanced braces should fail
ok( !$r->regex('(?{unclosed'), 'reject unbalanced eval' );
ok( !$r->regex('(??{unclosed'), 'reject unbalanced logical' );
