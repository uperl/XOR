package XOR::Link {

  # ABSTRACT: Links

  use strict;
  use warnings;
  use 5.024;
  use experimental qw( signatures postderef );
  use URI;
  use XOR;
  use JSON::MaybeXS qw( decode_json );

=head1 CONSTRUCTOR

=head2 new

=cut

  sub new ($class, $href, $name=undef)
  {
    $href = URI->new($href);
    $name //= $href->host;
    my $self = bless {
      href => $href,
      name => $name,
    }, $class;
  }

=head1 METHODS

=head2 href

=head2 name

=cut

  sub href ($self) { $self->{href} }
  sub name ($self) { $self->{name} }

=head2 fetch_site_links

=cut

  sub fetch_site_links ($class, $url=undef)
  {
    $url //= "https://wdlabs.com/sites.json";
    map { __PACKAGE__->new($_->{href}, $_->{name}) } decode_json(XOR->new->web->get($url))->@*;
  }

}

1;
