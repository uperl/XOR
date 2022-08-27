package XOR::Builder {

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use XOR;

  sub new ($class)
  {
    bless {}, $class;
  }

  sub build ($self)
  {
    my $xor = XOR->new;
    my $tt = $xor->tt;
    my $pods = $xor->pods;

    foreach my $url (XOR->new->tarball_list->get('PerlAlien')->@*)
    {
      $pods->add_dist($url);
    }
    $pods->fs_root->remove_tree;
    $pods->generate_html;

    $xor->root->child('docs')->visit(
      sub ($md_path, $) {
        return unless $md_path->basename =~ /\.md$/;

        my($html_path, undef, $template_name) = $md_path->basename =~ /^(.*?)(\.(.*))?\.md$/;

        $template_name ||= 'simple';
        $html_path = $md_path->sibling($html_path . '.html');

        my $out = '';

        my @lines = $md_path->lines_utf8;
        my $title = 'alienfile.org';
        my $h1;

        if($lines[0] =~ m/^#+\s*(\S.*)$/)
        {
          $h1 = $title = $1;
          shift @lines;
        }

        my $template_path = $xor->root->child("templates/$template_name.html.tt");
        say "$md_path ($template_path)";
        die "no such tempalte $template_path" unless -f $template_path;

        my $html = $tt->process(
          $template_path->basename,
          {
            title     => $title,
            h1        => $h1,
            markdown  => XOR->new->markdown->markdown(join('', @lines)),
            directory => $md_path->parent,
            shjs      => "https://shjs.wdlabs.com",
          },
          \$out,
        ) || die $tt->error;

        say "  -> $html_path";

        $html_path->spew_utf8($out);

      },
      { recurse => 1 },
    );
  }
}

1;
