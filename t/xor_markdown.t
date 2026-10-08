use Test2::V0 -no_srand => 1;
use XOR;
use XOR::Markdown;
use Path::Tiny qw( tempdir );

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

is(
  $md->markdown("M<PerlX::Define#SYNOPSIS>"),
  "<p><a href=\"https://metacpan.org/pod/PerlX::Define#SYNOPSIS\" class=\"module\">PerlX::Define</a></p>\n",
);

subtest 'T<>' => sub {

  my $dir = tempdir;

  $dir->child('full.json')->spew_utf8(<<~'JSON');
    {
      "header": [ "Name", ["Author"], {"content":"Link","link":"https://example.com/?a=1&b=2"} ],
      "rows": [
        [ "a < b & c", ["d", "https://example.com/d"], {"content":"e"} ],
        [ ["f"], {"content":"g","link":"g.html"}, 42 ]
      ]
    }
    JSON

  $dir->child('rows.json')->spew_utf8('{"rows":[["x"]]}');

  is(
    $md->markdown("before\n\nT<full.json|foo>\n\nafter\n", { base => $dir }),
    join("\n",
      '<p>before</p>',
      '',
      '<table class="foo">',
      '<thead>',
      '<tr><th>Name</th><th>Author</th><th><a href="https://example.com/?a=1&amp;b=2">Link</a></th></tr>',
      '</thead>',
      '<tbody>',
      '<tr><td>a &lt; b &amp; c</td><td><a href="https://example.com/d">d</a></td><td>e</td></tr>',
      '<tr><td>f</td><td><a href="g.html">g</a></td><td>42</td></tr>',
      '</tbody>',
      '</table>',
      '',
      '<p>after</p>',
      '',
    ),
    'full table with header and class',
  );

  is(
    $md->markdown("T<rows.json>\n", { base => $dir }),
    "<table>\n<tbody>\n<tr><td>x</td></tr>\n</tbody>\n</table>\n",
    'no header, no class',
  );

  is(
    $md->markdown("T<@{[ $dir->child('rows.json') ]}>\n"),
    "<table>\n<tbody>\n<tr><td>x</td></tr>\n</tbody>\n</table>\n",
    'absolute path without base',
  );

  is(
    $md->markdown("inline T<rows.json> is not a table\n", { base => $dir }),
    "<p>inline T<rows.json> is not a table</p>\n",
    'not on a line by itself',
  );

  like dies { $md->markdown("T<rows.json>\n") }, qr/relative path with no base/, 'no base';
  like dies { $md->markdown("T<nope.json>\n", { base => $dir }) }, qr/unable to read/, 'missing file';

  my %bad = (
    'invalid JSON'           => [ '{"rows":',                    qr/invalid JSON/ ],
    'top level array'        => [ '[]',                          qr/top level must be an object/ ],
    'unknown top level key'  => [ '{"rows":[],"foo":1}',         qr/unknown key foo/ ],
    'missing rows'           => [ '{"header":["a"]}',            qr/rows is required/ ],
    'rows not array'         => [ '{"rows":{}}',                 qr/rows must be an array/ ],
    'header not array'       => [ '{"header":"a","rows":[]}',    qr/header must be an array/ ],
    'row not array'          => [ '{"rows":["a"]}',              qr/rows\[0\] must be an array/ ],
    'empty cell array'       => [ '{"rows":[[[]]]}',             qr/rows\[0\]\[0\]: cell array must have one or two elements/ ],
    'long cell array'        => [ '{"rows":[[["a","b","c"]]]}',  qr/cell array must have one or two elements/ ],
    'cell object no content' => [ '{"rows":[[{"link":"x"}]]}',   qr/cell object must have content/ ],
    'unknown cell key'       => [ '{"rows":[[{"content":"a","foo":1}]]}', qr/unknown cell key foo/ ],
    'null cell'              => [ '{"rows":[["a",null]]}',       qr/rows\[0\]\[1\]: cell content must be a string/ ],
    'nested content'         => [ '{"header":[[["a"]]],"rows":[]}', qr/header\[0\]: cell content must be a string/ ],
    'null link'              => [ '{"rows":[[["a",null]]]}',     qr/cell link must be a string/ ],
  );

  foreach my $name (sort keys %bad)
  {
    my($json, $re) = $bad{$name}->@*;
    $dir->child('bad.json')->spew_utf8($json);
    like dies { $md->markdown("T<bad.json>\n", { base => $dir }) }, $re, $name;
  }

};

done_testing;
