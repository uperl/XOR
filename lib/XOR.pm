package XOR {

  # ABSTRACT: Website builder for alienfile.org and others

  use strict;
  use warnings;
  use 5.024;
  use experimental qw( signatures );
  use XOR::Pods;
  use XOR::Web;
  use XOR::Markdown;
  use XOR::TarballList;
  use XOR::Builder;
  use Path::Tiny ();
  use YAML ();

=head1 SYNOPSIS

 use XOR;

 my $xor = XOR->new(
   root      => '.',
   org       => 'uperl',
   site_name => 'My Site',
 );

 $xor->builder->build;

=head1 DESCRIPTION

This module is the core of a static website builder used to generate
alienfile.org and some other sites.  It does two things:

=over 4

=item Markdown to HTML

Every C<.md> file under L</docs_root> is rendered into an C<.html> file
in the same directory using L<Template> Toolkit templates.  See
L<XOR::Builder> for the details.

=item POD to HTML

If an L</org> is given, then the latest CPAN release of each
(un-archived) repository in that GitHub organization is downloaded and
its POD is rendered into HTML under the C<pod> directory of
L</docs_root>.  See L<XOR::Pods> for the details.

=back

The C<XOR> object is a singleton.  The first call to L</new> creates it,
and all subsequent calls return the same object, ignoring any
arguments.  This lets the other C<XOR::> classes get at the
configuration with C<< XOR->new >>.

Templates are searched for first in the C<templates> directory under
L</root>, and then in the C<templates> directory of this distribution's
L<share directory|/share_dir>.

=head1 CONSTRUCTOR

=head2 new

 my $xor = XOR->new(%args);

Creates the singleton instance, or returns it if it has already been
created (in which case C<%args> is ignored).  Supported arguments:

=over 4

=item root

The root directory of the website project.  Site specific templates are
looked for in the C<templates> subdirectory of this directory, and the
generated C<test.psgi> is written here.

=item docs_root

The directory containing the website content.  This is where the
Markdown is read from and the HTML is written to.  Defaults to the
C<docs> subdirectory of C<root>.

=item org

The GitHub organization whose CPAN distributions should have their
documentation generated.  If not provided then no POD is rendered.

=item site_name

The name of the site.  This is used as the page title for Markdown files
which do not start with a header.

=back

=cut

  sub new ($class, %args)
  {
    state $singleton;
    $singleton ||= do {
      my $self = bless {
        root      => Path::Tiny->new($args{root})->absolute,
        org       => $args{org},
        site_name => $args{site_name},
      }, __PACKAGE__;

      if(defined $args{docs_root})
      {
        $self->{docs_root} = Path::Tiny->new($args{docs_root})->absolute;
      }
      else
      {
        $self->{docs_root} = $self->root->child('docs');
      }

      $self;
    };
  }

=head1 METHODS

=head2 pods

 my $pods = $xor->pods;

Returns the L<XOR::Pods> instance used to render POD.

=cut

  sub pods ($self)
  {
    $self->{pods} ||= XOR::Pods->new;
  }

=head2 web

 my $web = $xor->web;

Returns the L<XOR::Web> instance used to make (cached) HTTP requests.

=cut

  sub web ($self)
  {
    $self->{web} ||= XOR::Web->new;
  }

=head2 markdown

 my $md = $xor->markdown;

Returns the L<XOR::Markdown> instance used to render Markdown.

=cut

  sub markdown ($self)
  {
    $self->{markdown} ||= XOR::Markdown->new;
  }

=head2 tt

 my $tt = $xor->tt;

Returns the L<Template> instance used to render pages.  It uses
C<wrapper.html.tt> as the wrapper template, and searches the
C<templates> directory under L</root> and then under L</share_dir> for
templates.

=cut

  sub tt ($self)
  {
    $self->{tt} ||= Template->new(
      WRAPPER            => 'wrapper.html.tt',
      INCLUDE_PATH       => [map { $_->stringify } $self->root->child('templates'), $self->share_dir->child('templates')],
      render_die         => 1,
      TEMPLATE_EXTENSION => '.tt',
      ENCODING           => 'utf8',
    );
  }

=head2 tarball_list

 my $list = $xor->tarball_list;

Returns the L<XOR::TarballList> instance used to find CPAN tarballs for
the GitHub organization.

=cut

  sub tarball_list ($self)
  {
    $self->{tarball_list} ||= XOR::TarballList->new;
  }

=head2 builder

 my $builder = $xor->builder;

Returns the L<XOR::Builder> instance used to build the site.

=cut

  sub builder ($self)
  {
    $self->{builder} ||= XOR::Builder->new;
  }

=head2 root

 my $root = $xor->root;

Returns the root directory of the website project as an absolute
L<Path::Tiny> object.

=cut

  sub root ($self)
  {
    $self->{root};
  }

=head2 docs_root

 my $docs_root = $xor->docs_root;

Returns the content directory of the website as an absolute
L<Path::Tiny> object.

=cut

  sub docs_root ($self)
  {
    $self->{docs_root};
  }

=head2 org

 my $org = $xor->org;

Returns the GitHub organization, if any.

=cut

  sub org ($self)
  {
    $self->{org};
  }

=head2 site_name

 my $name = $xor->site_name;

Returns the name of the site.

=cut

  sub site_name ($self)
  {
    $self->{site_name};
  }

=head2 site_links

 my $links = $xor->site_links;

Returns an array reference of L<XOR::Link> objects for sister sites,
which are fetched from L<https://www.wdlabs.com/sites.json>.  These are
rendered in the footer of the default wrapper template.

=cut

  sub site_links ($self)
  {
    $self->{site_links} //= do {
      require XOR::Link;
      [XOR::Link->fetch_site_links];
    };
  }

=head2 share_dir

 my $dir = $xor->share_dir;

Returns the share directory for this distribution as an absolute
L<Path::Tiny> object.  This contains the default templates and
C<favicon.ico>.

=cut

  sub share_dir ($self)
  {
    require File::ShareDir::Dist;
    $self->{share_dir} ||= Path::Tiny->new(File::ShareDir::Dist::dist_share(__PACKAGE__))->absolute;
  }

=head2 common_vars

 my %vars = $xor->common_vars;

Returns a list of key/value pairs which are passed into every
template.  These include:

=over 4

=item shjs

The base URL for the SHJS syntax highlighter.

=item hatch

The base URL for the site CSS.

=item site.links

The same list of links as returned by L</site_links>.

=back

=cut

  sub common_vars ($self)
  {
    $self->{common_vars} //= {
      shjs      => "https://shjs.wdlabs.com",
      hatch     => "https://hatch.wdlabs.com",
      site      => {
        links => $self->site_links,
      },
    };
    $self->{common_vars}->%*;
  }

}

1;
