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

=head1 CONSTRUCTOR

=head2 new

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

=cut

  sub pods ($self)
  {
    $self->{pods} ||= XOR::Pods->new;
  }

=head2 web

=cut

  sub web ($self)
  {
    $self->{web} ||= XOR::Web->new;
  }

=head2 markdown

=cut

  sub markdown ($self)
  {
    $self->{markdown} ||= XOR::Markdown->new;
  }

=head2 tt

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

=cut

  sub tarball_list ($self)
  {
    $self->{tarball_list} ||= XOR::TarballList->new;
  }

=head2 builder

=cut

  sub builder ($self)
  {
    $self->{builder} ||= XOR::Builder->new;
  }

=head2 root

=cut

  sub root ($self)
  {
    $self->{root};
  }

=head2 docs_root

=cut

  sub docs_root ($self)
  {
    $self->{docs_root};
  }

=head2 org

=cut

  sub org ($self)
  {
    $self->{org};
  }

=head2 site_name

=cut

  sub site_name ($self)
  {
    $self->{site_name};
  }

=head2 site_links

=cut

  sub site_links ($self)
  {
    $self->{site_links} //= do {
      require XOR::Link;
      [XOR::Link->fetch_site_links];
    };
  }

=head2 share_dir

=cut

  sub share_dir ($self)
  {
    require File::ShareDir::Dist;
    $self->{share_dir} ||= Path::Tiny->new(File::ShareDir::Dist::dist_share(__PACKAGE__))->absolute;
  }

=head2 common_vars

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
