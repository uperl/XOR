package Template::Plugin::XOR {

  # ABSTRACT: Template Toolkit filters for XOR

  use strict;
  use warnings;
  use 5.020;
  use experimental qw( signatures );
  use XOR;
  use base qw (Template::Plugin::Filter);

=head1 SYNOPSIS

 [% USE XOR %]
 [% text | markdown %]
 [% text | summary(href) | markdown %]

=head1 DESCRIPTION

This L<Template> Toolkit plugin provides filters for rendering Markdown
in templates.  The C<XOR> singleton must already have been created.

=head1 FILTERS

=head2 markdown

 [% text | markdown %]

Renders Markdown as HTML using L<XOR::Markdown>.

=head2 summary

 [% text | summary(href) | markdown %]

Reduces Markdown text to a summary, suitable for an index of blog posts
or similar.  Anything after a horizontal rule (C<--->) is removed.  If
the text contains a C<< <!-- summary --> >> marker, then everything
before the marker is used, otherwise the first five paragraphs are
used.  The leading header is turned into a link to C<href>, and a
C<[... read more]> link to C<href> is appended.  The output is still
Markdown, so you will usually want to follow it with the
L</markdown> filter.

=head1 CONSTRUCTOR

=head2 new

Called by L<Template> when the plugin is loaded with C<USE>.  Defines
the L</FILTERS> in the template context.

=cut

  sub new ($class, $context, @args)
  {
    my $self = bless {
      _CONTEXT => $context,
    }, $class;

    $context->define_filter(
      markdown => sub ($text) {
        XOR->new->markdown->markdown($text);
      },
    );

    $context->define_filter(
      summary => sub {
        my(undef, $link) = @_;

        sub {
          my $text = shift;

          # strip off anything under a hr
          ($text) = split /\n---\n/, $text;

          my $more = "[... read more]($link)";

          if($text =~ /\<\!-- summary --\>/)
          {
            # document contains summary mark
            ($text) = split /\<\!-- summary --\>/, $text;
            $text =~ s/^(#+) (.*)\n(.*)/$1 [$2]($link)\n$3/;
            $text .= "\n\n$more\n";
          }
          else
          {
            # include the first 5 "paragraphs" for the summary
            my @para = split /\n\n/, $text;
            $para[0] =~ s/^(#+) (.*)$/$1 [$2]($link)/;
            $text = join("\n\n", @para[0..4]) . "\n\n$more\n";
          }

          $text;
        }
      }, 1,
    );

    return $self;
  }

}

1;
