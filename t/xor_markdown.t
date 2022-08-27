use Test2::V0 -no_srand => 1;
use XOR;
use XOR::Markdown;

XOR->new( root => '.' );

my $md = XOR::Markdown->new;
isa_ok $md, 'XOR::Markdown';

is(
  $md->markdown("\n```\nuse strict;\nuse warnings;\n```\n"),
  "<p><code>\nuse strict;\nuse warnings;\n</code></p>\n",
);

is(
  $md->markdown("\n```perl\nuse strict;\nuse warnings;\n```\n"),
  "<p><pre class=\"sh_perl\">use strict;\nuse warnings;\n</pre></p>\n",
);

is(
  $md->markdown("M<PerlX::Define>"),
  "<p><a href=\"https://metacpan.org/pod/PerlX::Define\" class=\"module\">PerlX::Define</a></p>\n",
);

done_testing;
