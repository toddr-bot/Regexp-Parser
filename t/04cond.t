# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Regexp-Parser.t'

use strict;
use warnings;

use Test::More tests => 122;
use Regexp::Parser;

my $r = Regexp::Parser->new;

my @good_rx = (
  q{(?(?=a|b)c|d)},
  q{(?(?<=a|b)c|d)},
  q{(?(?!a|b)c|d)},
  q{(?(?<!a|b)c|d)},
  q{(?(?{1})c|d)},
  q{(?(1)c|d)},
  q{(?(DEFINE)(?<foo>bar))},
  q{(?(DEFINE)(?<digit>[0-9])(?<word>[a-z]+))},
);

my @bad_rx = (
  q{(?(??{bad})c|d)},
  q{(?(?p{bad})c|d)},
  q{(?(?>bad)c|d)},
  q{(?(?:bad)c|d)},
  q{(?(?i)c|d)},
  q{(?(?#bad)c|d)},
  q{(?(BAD)c|d)},
  q{(?(1BAD)c|d)},
  q{(?()c|d)},
  q{(?((?=bad))c|d)},
  q{(?(?=bad)c|d|e)},
);

my @not_bad = (
  q{(?(?=a)(b|c)(d|e))},
  q{(?(?=a)(?(?=b)c|d))},
  q{(?(?=a)(?(?=b)c|d)|(?(?=e)f|g))},
);

for my $rx (@good_rx) {
  ok( $r->regex($rx), "parse $rx" );
  ok( my $w = $r->walker, "walker for $rx" );
  while (my ($n, $d) = $w->()) {
    chomp(my $exp = <DATA>);
    my $got = join("\t", $d, $n->family, $n->type);
    my $vis = $n->visual;
    $got .= "\t$vis" if length $vis;
    is( $got, $exp, "node: $exp" );
  }
  is( scalar(<DATA>), "DONE\n", "walker done for $rx" );
}

for my $rx (@bad_rx) { ok( !$r->regex($rx), "reject $rx" ) }
for my $rx (@not_bad) { ok( $r->regex($rx), "accept $rx" ) }

__DATA__
0	assertion	ifthen	(?(?=a|b)c|d)
1	assertion	ifmatch	(?=a|b)
2	branch	branch	a|b
3	exact	exact	a
2	branch	branch
3	exact	exact	b
1	close	tail
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(?<=a|b)c|d)
1	assertion	ifmatch	(?<=a|b)
2	branch	branch	a|b
3	exact	exact	a
2	branch	branch
3	exact	exact	b
1	close	tail
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(?!a|b)c|d)
1	assertion	unlessm	(?!a|b)
2	branch	branch	a|b
3	exact	exact	a
2	branch	branch
3	exact	exact	b
1	close	tail
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(?<!a|b)c|d)
1	assertion	unlessm	(?<!a|b)
2	branch	branch	a|b
3	exact	exact	a
2	branch	branch
3	exact	exact	b
1	close	tail
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(?{1})c|d)
1	assertion	eval	(?{1})
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(1)c|d)
1	groupp	groupp1	(1)
1	branch	branch	c|d
2	exact	exact	c
1	branch	branch
2	exact	exact	d
0	close	tail
DONE
0	assertion	ifthen	(?(DEFINE)(?<foo>bar))
1	define	define	(DEFINE)
1	branch	branch	(?<foo>bar)
2	open	open1	(?<foo>bar)
3	exact	exact	bar
2	close	close1
0	close	tail
DONE
0	assertion	ifthen	(?(DEFINE)(?<digit>[0-9])(?<word>[a-z]+))
1	define	define	(DEFINE)
1	branch	branch	(?<digit>[0-9])(?<word>[a-z]+)
2	open	open1	(?<digit>[0-9])
3	anyof	anyof	[0-9]
4	anyof_range	anyof_range	0-9
3	close	anyof_close
2	close	close1
2	open	open2	(?<word>[a-z]+)
3	quant	plus	[a-z]+
4	anyof	anyof	[a-z]
5	anyof_range	anyof_range	a-z
4	close	anyof_close
2	close	close2
0	close	tail
DONE
