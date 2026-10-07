package XOR::Link {

  # ABSTRACT: Links

  use strict;
  use warnings;
  use 5.024;
  use experimental qw( signatures postderef );
  use URI;
  use XOR;
  use JSON::MaybeXS qw( decode_json );

=head1 SYNOPSIS

 use XOR::Link;

 my $link = XOR::Link->new('https://alienfile.org', 'Alien');
 say $link->name;  # Alien
 say $link->href;  # https://alienfile.org

 my @links = XOR::Link->fetch_site_links;

=head1 DESCRIPTION

This class represents a link to another site, and is used for the site
links in the footer of the default wrapper template.

=head1 CONSTRUCTOR

=head2 new

 my $link = XOR::Link->new($href);
 my $link = XOR::Link->new($href, $name);

Create a new link.  If C<$name> is not provided, then the host of
C<$href> is used.

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

 my $uri = $link->href;

Returns the URL of the link as a L<URI> object.

=head2 name

 my $name = $link->name;

Returns the display name of the link.

=cut

  sub href ($self) { $self->{href} }
  sub name ($self) { $self->{name} }

=head2 fetch_site_links

 my @links = XOR::Link->fetch_site_links;
 my @links = XOR::Link->fetch_site_links($url);

Fetches a JSON list of sites from C<$url> and returns them as a list of
C<XOR::Link> objects.  The JSON should be an array of objects with
C<href> and C<name> keys.  If C<$url> is not provided, then
L<https://www.wdlabs.com/sites.json> is used.  The C<XOR> singleton
must already have been created.

=cut

  sub fetch_site_links ($class, $url=undef)
  {
    $url //= "https://www.wdlabs.com/sites.json";
    map { __PACKAGE__->new($_->{href}, $_->{name}) } decode_json(XOR->new->web->get($url))->@*;
  }

}

1;
