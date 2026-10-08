package XOR::Builder {

  # ABSTRACT: Build the website

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use XOR;

=head1 SYNOPSIS

 use XOR;

 XOR->new( root => '.', site_name => 'My Site' )->builder->build;

=head1 DESCRIPTION

This class builds the website, using the configuration from the L<XOR>
singleton.  You will normally get an instance from
L<XOR's builder method|XOR/builder>, rather than creating one directly.

=head1 CONSTRUCTOR

=head2 new

 my $builder = XOR::Builder->new;

Create a new builder instance.

=cut

  sub new ($class)
  {
    bless {}, $class;
  }

=head1 METHODS

=head2 build

 $builder->build;

Builds the website.  The C<XOR> singleton must already have been
created.  This does the following:

=over 4

=item 1.

If an L<org|XOR/org> was provided, then the latest CPAN tarball of each
repository in that GitHub organization is added to L<XOR::Pods> using
L<add_dist|XOR::Pods/add_dist>.

=item 2.

The C<pod> directory under L<docs_root|XOR/docs_root> is B<removed>, and
the POD HTML is regenerated using
L<generate_html|XOR::Pods/generate_html>.

=item 3.

The default C<favicon.ico> is copied into L<docs_root|XOR/docs_root>,
unless one already exists there.

=item 4.

A C<test.psgi> is written to L<root|XOR/root>, which can be used to
preview the site locally, for example with C<plackup test.psgi>.  This
file is overwritten every time, so you should not edit it.

=item 5.

Every Markdown file under L<docs_root|XOR/docs_root> is rendered as HTML
into the same directory.  A file named C<foo.md> is written to
C<foo.html> using the C<simple.html.tt> template.  A different template
can be selected by adding an extra extension: C<foo.bar.md> is written
to C<foo.html> using the C<bar.html.tt> template.  If the first line of
the Markdown file is a header, then it is removed from the content and
used as the title and C<h1> of the page, otherwise the
L<site_name|XOR/site_name> is used as the title.

The template is processed with these variables, in addition to the
L<common variables|XOR/common_vars>:

=over 4

=item title

The page title.

=item h1

The page header, if any.

=item markdown

The content rendered as HTML by L<XOR::Markdown>.

=item directory

The directory containing the Markdown file, as a L<Path::Tiny> object.

=back

=back

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
    }

    {
      my $pods = $xor->pods;
      $pods->fs_root->remove_tree;
      $pods->generate_html;
    }

    {
      my $fav = $xor->docs_root->child('favicon.ico');
      $xor->share_dir->child('favicon.ico')->copy($fav) unless -f $fav;
    }

    {
      my $test_psgi = $xor->root->child('test.psgi');
      my $docs_root = $xor->docs_root->relative($test_psgi->parent);
      $test_psgi->spew_utf8(
        join("\n",
          '#!/usr/bin/env perl',
          '# warning, this file is generated',
          'use strict;',
          'use warnings;',
          'use Plack::Builder;',
          'use Plack::App::GitHubPages::Faux;',
          'builder {',
          '  enable "Headers", set => ["cache-control" => "no-cache"];',
          "  Plack::App::GitHubPages::Faux->new( root => \"$docs_root\" )->to_app;",
          '};',
        )
      );
      chmod 0755, $test_psgi;
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
            markdown  => XOR->new->markdown->markdown(join('', @lines), { base => $md_path->parent }),
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
