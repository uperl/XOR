use strict;
use warnings;
use 5.020;
use experimental qw( signatures postderef );

package XOR::Pods {

  use Archive::Libarchive::Peek;
  use URI;
  use URI::file;
  use Path::Tiny ();
  use JSON::MaybeXS qw( decode_json JSON );
  use Template;
  use XOR;

=head1 CONSTRUCTOR

=head2 new

=cut

  sub new ($class) {
    bless {}, $class;
  }

=head1 METHODS

=head2 current

=cut

  sub current ($self, $new=undef) {
    if(defined $new) {
      $self->{current} = $new;
    }
    $self->{current};
  }

=head2 fs_root

=cut

  sub fs_root ($self) {
    $self->{fs_root} ||= XOR->new->docs_root->child('pod');
  }

=head2 url_prefix

=cut

  sub url_prefix ($self, $new=undef) {
    $self->{url_prefix} = $new if defined $new;
    $self->{url_prefix} ||= "/pod/"
  }

=head2 add_dist

=cut

  sub add_dist ($self, $location) {
    my $url = -f $location ? URI::file->new(Path::Tiny->new($location)->absolute->stringify) : URI->new($location);
    say "$url";
    my $tarball = XOR->new->web->get($url);

    my $peek = Archive::Libarchive::Peek->new(
      memory => \$tarball,
    );

    my @pod_list;
    my $dist_name;

    $peek->iterate(sub ($filename, $content, $e) {
      return unless $e->filetype eq 'reg';

      # want to also handle bin directory
      if($filename =~ m{^[^/]+/lib/(.+)$})
      {
        my $path = $1;
        if($path =~ /\.(pod|pm)$/)
        {
          my $name = $path;
          $name =~ s{\.(pod|pm)$}{};
          $name =~ s{/}{::}g;

          my $href = $path;
          $href =~ s{\.(pod|pm)$}{.html};

          $self->{pod}->{$name} = {
            content => $content,
            href    => $self->url_prefix . $href,
          };
          push @pod_list, $name;
        }
        else
        {
          return if $path =~ /\.xs$/;
          return if $path =~ /\/typemap$/;
          say "data: $path";
          $self->{data}->{$path} = $content;
        }
      }
      elsif($filename =~ m{^[^/]+/bin/(.+)$})
      {
        my $name = $1;
        $self->{pod}->{$name} = {
          content => $content,
          href    => $self->url_prefix . "$name.html",
        };
        push @pod_list, $name;
      }
      elsif($filename =~  m{^[^/]+/META.json$})
      {
        my $meta = decode_json($content);
        $dist_name = $meta->{name};
      }
    });

    if($dist_name)
    {
      $self->{dist}->{$dist_name} = [ sort @pod_list ];
    }
    else
    {
      warn "unknown dist for $url";
    }
  }

=head2 add_sister_site

=cut

  sub add_sister_site ($self, $url) {
    $url = URI->new($url) unless ref $url;
    my $index_url = $url->clone;
    $index_url->path("/pod/index.json");
    say $url;
    foreach my $dist (decode_json(XOR->new->web->get($index_url))->@*)
    {
      foreach my $pod ($dist->{pods}->@*)
      {
        my $pod_url = $url->clone;
        $pod_url->path($pod->{href});
        $self->{sister_pod}->{$pod->{name}}->{href} = $pod_url->as_string;
      }
    }
  }

=head2 generate_html

=cut

  sub generate_html ($self) {

    # write out each pod file as .html
    foreach my $name (sort keys $self->{pod}->%*)
    {
      my $p = XOR::Pods::HTML->new;
      my $html;
      $p->output_string(\$html);
      $p->index(1);
      $p->html_header_before_title('<!--');
      $p->html_header_after_title('-->');
      $p->html_footer('');
      $p->pods($self);
      $p->{Tagmap}->{'Verbatim'} = "\n<pre class=\"sh_perl\">";
      $p->{Tagmap}->{'VerbatimFormatted'} = "\n<pre class=\"sh_perl\">";
      $self->current($name);

      $p->parse_string_document($self->{pod}->{$name}->{content});

      my $path = $self->fs_root->child(do {
        my @parts = split /::/, $name;
        $parts[-1] .= '.html';
        @parts;
      });

      $path->parent->mkpath;

      my $h1;
      if($name =~ /::/)
      {
        my @parts = split /::/, $name;
        my $last = pop @parts;
        my $sofar;
        foreach my $part (@parts)
        {
          if(defined $sofar)
          {
            $sofar .= "::$part";
            $h1 .= "::";
          }
          else
          {
            $sofar = $part;
          }
          my $href = $self->get_link($sofar);
          if(defined $href)
          {
            $h1 .= "<a href=\"$href\">$part</a>";
          }
          else
          {
            $h1 .= $part;
          }
        }
        $h1 .= "::$last";
      }
      else
      {
        $h1 = $name;
      }

      my $full_html;
      my $xor = XOR->new;
      $xor->tt->process('pod.html.tt', {
        title => $name,
        h1    => $h1,
        pod   => $html,
        $xor->common_vars,
      }, \$full_html);

      $path->spew_utf8($full_html);
    }

    # write out data files, images, etc.
    foreach my $path (sort keys $self->{data}->%*) {
      my $content = $self->{data}->{$path};
      $path = $self->fs_root->child($path);
      $path->parent->mkpath;
      $path->spew_raw($content);
    }

    # generate the dist index
    {
      my @dists;

      foreach my $dist_name (sort keys $self->{dist}->%*)
      {
        push @dists, { name => $dist_name, pods => [ map { { href => $self->get_link($_), name => $_ } } $self->{dist}->{$dist_name}->@* ] };
      }

      my $html;
      my $xor = XOR->new;
      $xor->tt->process('dist.html.tt', {
        title => 'Documentation',
        dists => \@dists,
        $xor->common_vars,
      }, \$html);

      $self->fs_root->child('index.html')->spew_utf8($html);
      $self->fs_root->child('index.json')->spew_raw(JSON()->new->canonical->pretty->encode(\@dists));
    }
  }

=head2 get_link

=cut

  sub get_link ($self, $name) {
    $self->{pod}->{$name}->{href} // $self->{sister_pod}->{$name}->{href};
  }

}

package XOR::Pods::HTML {

  use parent qw( Pod::Simple::HTML );

  sub pods ($self, $new=undef) {
    if($new) {
      $self->{pods} = $new;
    }
    $self->{pods};
  }

  sub do_pod_link ($self, $link)
  {
    if($link->tagname eq 'L' && $link->attr('type') eq 'pod') {
      my $to      = $link->attr('to');
      my $section = $link->attr('section');
      if(defined $to)
      {
        if(my $path = $self->pods->get_link($to)) {
          $path .= "#" . $self->section_escape($section) if defined $section;
          return $path;
        }
      }
      else
      {
        if(defined $section) {
          return "#" . $self->section_escape($section);
        }
      }
    }
    return $self->SUPER::do_pod_link($link);
  }

}

1;
