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

  sub new ($class)
  {
    bless {}, $class;
  }

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

  sub mcpan ($self)
  {
    $self->{mcpan} ||= MetaCPAN::Client->new(ua => $self->ua);
  }

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



