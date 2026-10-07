# XOR ![static](https://github.com/uperl/XOR/workflows/static/badge.svg) ![linux](https://github.com/uperl/XOR/workflows/linux/badge.svg)

Website builder for alienfile.org and others

# SYNOPSIS

    use XOR;

    my $xor = XOR->new(
      root      => '.',
      org       => 'uperl',
      site_name => 'My Site',
    );

    $xor->builder->build;

# DESCRIPTION

This module is the core of a static website builder used to generate
alienfile.org and some other sites.  It does two things:

- Markdown to HTML

    Every `.md` file under ["docs\_root"](#docs_root) is rendered into an `.html` file
    in the same directory using [Template](https://metacpan.org/pod/Template) Toolkit templates.  See
    [XOR::Builder](https://metacpan.org/pod/XOR%3A%3ABuilder) for the details.

- POD to HTML

    If an ["org"](#org) is given, then the latest CPAN release of each
    (un-archived) repository in that GitHub organization is downloaded and
    its POD is rendered into HTML under the `pod` directory of
    ["docs\_root"](#docs_root).  See [XOR::Pods](https://metacpan.org/pod/XOR%3A%3APods) for the details.

The `XOR` object is a singleton.  The first call to ["new"](#new) creates it,
and all subsequent calls return the same object, ignoring any
arguments.  This lets the other `XOR::` classes get at the
configuration with `XOR->new`.

Templates are searched for first in the `templates` directory under
["root"](#root), and then in the `templates` directory of this distribution's
[share directory](#share_dir).

# CONSTRUCTOR

## new

    my $xor = XOR->new(%args);

Creates the singleton instance, or returns it if it has already been
created (in which case `%args` is ignored).  Supported arguments:

- root

    The root directory of the website project.  Site specific templates are
    looked for in the `templates` subdirectory of this directory, and the
    generated `test.psgi` is written here.

- docs\_root

    The directory containing the website content.  This is where the
    Markdown is read from and the HTML is written to.  Defaults to the
    `docs` subdirectory of `root`.

- org

    The GitHub organization whose CPAN distributions should have their
    documentation generated.  If not provided then no POD is rendered.

- site\_name

    The name of the site.  This is used as the page title for Markdown files
    which do not start with a header.

# METHODS

## pods

    my $pods = $xor->pods;

Returns the [XOR::Pods](https://metacpan.org/pod/XOR%3A%3APods) instance used to render POD.

## web

    my $web = $xor->web;

Returns the [XOR::Web](https://metacpan.org/pod/XOR%3A%3AWeb) instance used to make (cached) HTTP requests.

## markdown

    my $md = $xor->markdown;

Returns the [XOR::Markdown](https://metacpan.org/pod/XOR%3A%3AMarkdown) instance used to render Markdown.

## tt

    my $tt = $xor->tt;

Returns the [Template](https://metacpan.org/pod/Template) instance used to render pages.  It uses
`wrapper.html.tt` as the wrapper template, and searches the
`templates` directory under ["root"](#root) and then under ["share\_dir"](#share_dir) for
templates.

## tarball\_list

    my $list = $xor->tarball_list;

Returns the [XOR::TarballList](https://metacpan.org/pod/XOR%3A%3ATarballList) instance used to find CPAN tarballs for
the GitHub organization.

## builder

    my $builder = $xor->builder;

Returns the [XOR::Builder](https://metacpan.org/pod/XOR%3A%3ABuilder) instance used to build the site.

## root

    my $root = $xor->root;

Returns the root directory of the website project as an absolute
[Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object.

## docs\_root

    my $docs_root = $xor->docs_root;

Returns the content directory of the website as an absolute
[Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object.

## org

    my $org = $xor->org;

Returns the GitHub organization, if any.

## site\_name

    my $name = $xor->site_name;

Returns the name of the site.

## site\_links

    my $links = $xor->site_links;

Returns an array reference of [XOR::Link](https://metacpan.org/pod/XOR%3A%3ALink) objects for sister sites,
which are fetched from [https://www.wdlabs.com/sites.json](https://www.wdlabs.com/sites.json).  These are
rendered in the footer of the default wrapper template.

## share\_dir

    my $dir = $xor->share_dir;

Returns the share directory for this distribution as an absolute
[Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object.  This contains the default templates and
`favicon.ico`.

## common\_vars

    my %vars = $xor->common_vars;

Returns a list of key/value pairs which are passed into every
template.  These include:

- shjs

    The base URL for the SHJS syntax highlighter.

- hatch

    The base URL for the site CSS.

- site.links

    The same list of links as returned by ["site\_links"](#site_links).

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2022-2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
