package XOR::Markdown {

  use strict;
  use warnings;
  use 5.020;
  use experimental qw( signatures postderef );
  use base 'Text::Markdown::PerlExtensions';
  use XOR;

=head1 CONSTRUCTOR

=head2 new

=cut

  sub new ($class, @args)
  {
    my $self = $class->SUPER::new(@args);

    $self->add_formatting_code( M => sub ($stuff) {
      my $text;
      my $fragment = '';

      if($stuff =~ s/(#.*)$//)
      {
        $fragment = $1;
      }
      if($stuff =~ s/^(.*)\|//)
      {
        $text = $1;
      }

      my $name = $stuff;
      $text //= $name;

      my $href = XOR->new->pods->get_link($name) // "https://metacpan.org/pod/$name$fragment";
      return qq{<a href="$href$fragment" class="module">$text</a>};
    });

    $self;
  }

  sub _DoCodeSpans ($self, $text)
  {
    $text =~ s@
            (?<!\\)        # Character before opening ` can't be a backslash
            (`+)        # $1 = Opening run of `
            ([a-z_0-9]+)\n
            (.+?)        # $2 = The code block
            (?<!`)
            \1            # Matching closer
            (?!`)
        @
             my $lang = "$2";
             my $c = "$3";
             $c =~ s/^[ \t]*//g; # leading whitespace
             $c =~ s/[ \t]*$//g; # trailing whitespace
             $c = $self->_EncodeCode($c);
            "<pre class=\"sh_$lang\">$c</pre>";
        @egsx;

    $text = $self->SUPER::_DoCodeSpans($text);

    $text;
  }
}

1;
