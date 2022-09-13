package XOR::Builder {

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use XOR;

=head1 CONSTRUCTOR

=head2 new

=cut

  sub new ($class)
  {
    bless {}, $class;
  }

=head1 METHODS

=head2 build

=cut

  sub build ($self)
  {
    my $xor = XOR->new;
    my $tt = $xor->tt;

    if($xor->org)
    {
      my $pods = $xor->pods;
      foreach my $url (XOR->new->tarball_list->get($xor->org)->@*)
      {
        $pods->add_dist($url);
      }
      $pods->fs_root->remove_tree;
      $pods->generate_html;
    }

    {
      my $fav = $xor->docs_root->child('favicon.ico');
      $xor->share_dir->child('favicon.ico')->copy($fav) unless -f $fav;
    }

    $xor->docs_root->visit(
      sub ($md_path, $) {
        return unless $md_path->basename =~ /\.md$/;

        my($html_path, undef, $template_name) = $md_path->basename =~ /^(.*?)(\.(.*))?\.md$/;

        $template_name ||= 'simple';
        $html_path = $md_path->sibling($html_path . '.html');

        my $out = '';

        my @lines = $md_path->lines_utf8;
        my $title = $xor->site_name;
        my $h1;

        if($lines[0] =~ m/^#+\s*(\S.*)$/)
        {
          $h1 = $title = $1;
          shift @lines;
        }

        my $template_path;

        foreach my $try (map { $_->child("templates/$template_name.html.tt") } $xor->root, $xor->share_dir)
        {
          if(-f $try)
          {
            $template_path = $try;
            last;
          }
        }

        die "no such tempalte $template_path" unless defined $template_path;
        say "$md_path ($template_path)";

        my $html = $tt->process(
          $template_path->basename,
          {
            title     => $title,
            h1        => $h1,
            markdown  => XOR->new->markdown->markdown(join('', @lines)),
            directory => $md_path->parent,
            $xor->common_vars,
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
