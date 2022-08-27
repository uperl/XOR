package XOR::TarballList {

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use JSON::MaybeXS qw( decode_json );
  use XOR;

  sub new ($class)
  {
    bless {}, $class;
  }

  sub get ($self, $org)
  {
    my %repos;
    my $web = XOR->new->web;

    $self->{$org} ||= do {
      for(my $page = 1; 1; $page++)
      {
        my $res = decode_json($web->get("https://api.github.com/orgs/$org/repos?page=$page"));

        last unless @$res > 0;

        foreach my $repo (@$res)
        {
          next if $repo->{archived};
          my $name = $repo->{name};
          my $set = $web->mcpan->release({ all => [ { distribution => $name }, { status => 'latest' } ] });
          if($set->total > 1)
          {
            die "latest release for $name returned @{[ $set->total ]} items";
          }
          elsif($set->total == 0)
          {
            say STDERR "warning: no release for $name";
            next;
          }
          my $release = $set->next;
          $repos{$name} = $release->download_url;
        }
      }

      [sort values %repos];
    }
  }
}

1;
