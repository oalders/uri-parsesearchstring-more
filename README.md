# NAME

URI::ParseSearchString::More - Extract search strings from more referrers.

# VERSION

version 0.19

# SYNOPSIS

    use URI::ParseSearchString::More ();
    my $more = URI::ParseSearchString::More->new;
    my $search_terms = $more->se_term( 'https://www.google.ca/search?q=perl' );

# DESCRIPTION

This module is a subclass of [URI::ParseSearchString](https://metacpan.org/pod/URI%3A%3AParseSearchString), so you can call any
methods on this object that you would call on a URI::ParseSearchString object.
This module works a little harder than its SuperClass to get you results. If
it fails, it will return to you the results that [URI::ParseSearchString](https://metacpan.org/pod/URI%3A%3AParseSearchString)
would have returned to you anyway, so it should function well as a drop-in
replacement.

[WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) is used to extract search strings from some URLs
which contain session info rather than search params.  Optionally,
[WWW::Mechanize::Cached](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached) can be used to cache your lookups. There is additional
parsing and also a guess() method which will return good results in many cases
of doubt.

Repository: [http://github.com/oalders/uri-parsesearchstring-more/tree/master](http://github.com/oalders/uri-parsesearchstring-more/tree/master)

# USAGE

    use URI::ParseSearchString::More ();
    my $more = URI::ParseSearchString::More->new;
    my $search_terms = $more->se_term( $url );

# URI::ParseSearchString

## parse\_search\_string( $url )

At this point, this is the only "extended" URI::ParseSearchString method.
This method performs the following bit of logic:

1) If the URL supplied looks to be a search query with session info rather
than search data in the URL, it will attempt to access the URL and extract the
search terms from the page returned.

2) If this returns no results, the URL will be processed by parse\_more()

3) If there are still no results, the results of URI::ParseSearchString::se\_term
will be returned.

WWW::Mechanize::Cached can be used to speed up your movement through large log
files which may contain multiple similar URLs:

    use URI::ParseSearchString::More ();
    my $more = URI::ParseSearchString::More->new;
    $more->set_cached( 1 );
    my $search_terms = $more->se_term( $url );

One interesting thing to note is that maps.google.\* URLs have 2 important
params: "q" and "near".   The same can be said for local.google.\*  I would
think the results would be incomplete without including the value of "near" in
the search terms for these searches.  So, expect the following results:

    my $url = 'http://local.google.ca/local?sc=1&hl=en&near=Stratford%20ON&btnG=Google%20Search&q=home%20health';
    my $terms = $more->parse_search_string( $url );

    # $terms will = "home health Stratford ON"

Engines with session info currently supported:

    aol.com

## se\_term( $url )

A convenience method which calls parse\_search\_string.

# URI::ParseSearchString::More

## blame

Returns the name of the module that came up with the results on the last
string parsed by parse\_search\_string().  Possible results:

    URI::ParseSearchString
    URI::ParseSearchString::More

## set\_cached( 0|1 )

Turn caching off and on.  As of version 0.08 caching is OFF by default.  See
KNOWN ISSUES below for more info on this.

## get\_cached

Returns 1 if caching is currently on, 0 if it is not.

## get\_mech

This gives you direct access to the Mechanize object.  If caching is enabled,
a [WWW::Mechanize::Cached](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached) object will be returned.  If caching is disabled,
a [WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) object will be returned.

If you know what you're doing, play around with it.  Caveat emptor.

    use URI::ParseSearchString::More ();
    my $more = URI::ParseSearchString::More->new;

    my $mech = $more->get_mech();
    $mech->agent('My Agent Name');

    my $url = '...';

    my $search_terms = $more->se_term( $url );

## parse\_more( $url )

Handles the bulk of More's parsing.  This is automatically called (if needed)
when you pass a search string to se\_term().  However, you may also call it
directly.  Just keep in mind that this method will NOT try to get results from
URI::ParseSearchString if it comes up empty.

## guess( $url )

For the most part, the parsing that goes on is done with specific search
engines (ie. the ones that we already know about) in mind.  However, in a lot
cases, a good guess is all that you need.  For example, a URI which contains
a query string with the parameter "q" or "query" is generally the product of
a search.  If se\_term() or parse\_more() has come up empty, guess may just
provide you with a valid search term.  Then again, it may not.  Caveat emptor.

# TO DO

I've pretty much added all of the search engines I care about.  If you'd like
something added, please get in touch.

# NOTES

Despite its low version number, this module is now stable.

# KNOWN ISSUES

As of 0.13 WWW::Mechanize::Cached 1.33 is required.  This solves the errors
which were being thrown by Storable.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2018 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
