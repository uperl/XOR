package XOR::TarballList {

  # ABSTRACT: Find CPAN tarballs for a GitHub organization

  use strict;
  use warnings;
  use 5.026;
  use experimental qw( signatures );
  use JSON::MaybeXS qw( decode_json );
  use XOR;

=head1 SYNOPSIS

 use XOR;

 my $urls = XOR->new->tarball_list->get('uperl');

=head1 DESCRIPTION

This class finds the CPAN tarballs for the repositories in a GitHub
organization.

=head1 CONSTRUCTOR

=head2 new

 my $list = XOR::TarballList->new;

Create a new instance.

=cut

  sub new ($class)
  {
    bless {}, $class;
  }

=head1 METHODS

=head2 get

 my $urls = $list->get($org);

Returns an array reference of download URLs for the latest CPAN release
of each repository in the GitHub organization C<$org>.  The repository
name is used as the CPAN distribution name.  Archived repositories are
skipped, as are repositories without a CPAN release (with a warning).
The result is cached per organization for the lifetime of the
object.

=cut

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
          # fetch the latest release directly rather than using a search,
          # which metacpan intermittently returns unfiltered (all releases)
          my $release = eval { $web->mcpan->release($name) };
          if(my $error = $@)
          {
            die $error unless $error =~ /Not Found/;
            say STDERR "warning: no release for $name";
            next;
          }
          $repos{$name} = $release->download_url;
        }
      }

      [sort values %repos];
    }
  }
}

1;
