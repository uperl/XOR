package Plack::Middleware::XOR::DirIndex {

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use parent qw( Plack::Middleware );
  use Plack::Util::Accessor qw( root );

=head1 METHODS

=head2 call

=cut

  sub call ($self, $env)
  {
    if($env->{PATH_INFO} =~ m{/$})
    {
      if(-f $self->root->child($env->{PATH_INFO}, 'index.html'))
      {
        $env->{PATH_INFO} .= "index.html";
      }
    }
    else
    {
      if(-d $self->root->child($env->{PATH_INFO}))
      {
        return [
          301,
          [ Location => "@{[ $env->{PATH_INFO} ]}/" ],
          [ '' ],
        ];
      }
    }

    $self->app->($env);
  }
}

1;
