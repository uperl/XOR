package XOR::Web {

  # ABSTRACT: Cached web client

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

=head1 SYNOPSIS

 use XOR;

 my $content = XOR->new->web->get('https://www.wdlabs.com/sites.json');

=head1 DESCRIPTION

This class provides a web client used for fetching tarballs and making
API calls.  Responses are cached on disk in C<~/.xor/cache> for 24
hours.  To force fresh responses you can remove that directory.

=head1 CONSTRUCTOR

=head2 new

 my $web = XOR::Web->new;

Create a new instance.

=cut

  sub new ($class)
  {
    bless {}, $class;
  }

=head1 METHODS

=head2 ua

 my $ua = $web->ua;

Returns the user agent.  This is an L<HTTP::Tiny> compatible
L<HTTP::Tiny::Mech> object using L<WWW::Mechanize::Cached> with a
L<CHI> file cache.

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
            # keep cache around for 24hrs
            expires_in => 60*60*24,
            driver   => 'File',
            root_dir => $dir->stringify,
          ),
        )
      );
    };
  }

=head2 mcpan

 my $mcpan = $web->mcpan;

Returns a L<MetaCPAN::Client> instance which uses the caching
L</ua>.

=cut

  sub mcpan ($self)
  {
    $self->{mcpan} ||= MetaCPAN::Client->new(ua => $self->ua);
  }

=head2 get

 my $content = $web->get($url);

Fetches C<$url> (a string or L<URI> object) and returns the content.
C<file:> URLs are read directly from the filesystem without caching.
Dies on error.

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
