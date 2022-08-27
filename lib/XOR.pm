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

  sub new ($class, %args)
  {
    state $singleton;
    $singleton ||= bless { root => Path::Tiny->new($args{root})->absolute }, __PACKAGE__;
  }

  sub pods ($self)
  {
    $self->{pods} ||= XOR::Pods->new;
  }

  sub web ($self)
  {
    $self->{web} ||= XOR::Web->new;
  }

  sub markdown ($self)
  {
    $self->{markdown} ||= XOR::Markdown->new;
  }

  sub tt ($self)
  {
    $self->{tt} ||= Template->new(
      WRAPPER            => 'wrapper.html.tt',
      INCLUDE_PATH       => $self->root->child('templates')->stringify,
      render_die         => 1,
      TEMPLATE_EXTENSION => '.tt',
      ENCODING           => 'utf8',
    );
  }

  sub tarball_list ($self)
  {
    $self->{tarball_list} ||= XOR::TarballList->new;
  }

  sub builder ($self)
  {
    $self->{builder} ||= XOR::Builder->new;
  }

  sub root ($self)
  {
    $self->{root};
  }

}

1;
