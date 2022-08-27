package XOR::Web {

  use strict;
  use warnings;
  use 5.020;
  use experimental qw( signatures );
  use Path::Tiny qw( path );
  use CHI;
  use WWW::Mechanize::Cached;
  use HTTP::Tiny::Mech;
  use URI;
  use MetaCPAN::Client;

=head1 CONSTRUCTOR

=head2 new

=cut

  sub new ($class)
  {
    bless {}, $class;
  }

=head1 METHODS

=head2 ua

=cut

  sub ua ($self)
  {
    $self->{ua} ||= do {
      my $dir = path('~/.xor/cache');
      $dir->mkpath;
      $dir->chmod(0700);
      HTTP::Tiny::Mech->new(
        mechua => WWW::Mechanize::Cached->new(
          cache => CHI->new(
            driver   => 'File',
            root_dir => $dir->stringify,
          ),
        )
      );
    };
  }

=head2 mcpan

=cut

  sub mcpan ($self)
  {
    $self->{mcpan} ||= MetaCPAN::Client->new(ua => $self->ua);
  }

=head2 get

=cut

  sub get ($self, $url)
  {
    $url = URI->new($url) unless ref $url;

    if($url->scheme eq 'file')
    {
      return path($url->file)->slurp_raw;
    }

    my $res = $self->ua->get($url);
    return $res->{content} if $res->{success};
    die "error fetching $url: @{[ $res->{status} ]} @{[ $res->{reason} ]}";
  }

}

1;
