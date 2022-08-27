package Plack::App::XOR {

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use base 'Plack::App::File';

=head1 METHODS

=head2 return_404

=cut

  sub return_404 ($self)
  {
    my $file = $self->root->child('404.html');
    return $self->SUPER::return_404 unless -f $file;
    my $not_found_html = $file->slurp;
    [
      404,
      [ 'Content-Type' => 'text/html', 'Content-Length' => length $not_found_html ],
      [ $not_found_html ],
    ];
  }

}

1;
