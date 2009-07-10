package URI::ParseSearchString::More;

use warnings;
use strict;

use base qw( URI::ParseSearchString );

our $VERSION = '0.11';

use CGI;
use Data::Dumper;
use List::Compare;
use Params::Validate qw( validate SCALAR );
use URI::Heuristic qw(uf_uristr);
use WWW::Mechanize::Cached;

my %search_regex = (
    aol => qr/AOL Search results for "(.*)"/,
    as  => qr{(?:WeatherStudio|Starware) (.*) Search Results},
    dogpile => qr{(.*) - Dogpile Web Search},
);

my %url_regex = (
    aol => qr{aol.com/(?:aol|aolcom)/search\?encquery=},
    as  => qr{as.\w+.com/dp/search\?x=},
    dogpile => qr{http://www.dogpile},
);

# local.yahoo.com should come before Yahoo as it has different
# params
my @engines = (
    'local.google',
    'maps.google',
    'googlesyndication',
    'google',
    'local.yahoo.com',
    'search.yahoo.com',
    'shopping.yahoo.com',
    'yahoo',
    'alltheweb.com',
    'errors.aol.com',
    'sucheaol.aol.de',
    'aol',
    'ask.*',
    'as.*.com',
    'att.net',
    'trustedsearch.com',
);

my %query_lookup = (

    'abcsok.no'                     => ['q'],
    'about.com'                     => ['terms'],
    'alltheweb.com'                 => ['q'],
    'answers.com'                   => ['s'],
    'aol'                           => ['query', 'q'],
    'as.*.com'                      => ['qry'],
    'ask.*'                         => ['q'],
    'att.net'                       => ['qry', 'q'],
    'baidu.com'                     => ['bs'],
    'blingo.com'                    => ['q'],
    'citysearch.com'                => ['query'],
    'clicknow.org.uk'               => ['q'],
    'clusty.com'                    => ['query'],
    'comcast.net'                   => ['query', 'q'],
    'cuil.com'                      => ['q'],
    'danielsearch.info'             => ['q'],
    'devilfinder.com'               => ['q'],
    'ebay'                          => ['satitle'],
    'education.yahoo.com'           => ['p'],
    'errors.aol.com'                => ['host'],
    'excite'                        => ['search'],
    'ez4search.com'                 => ['searchname'],
    'fedstats.com'                  => ['s'],
    'find.copernic.com'             => ['query'],
    'finna.is'                      => ['query'],
    'googlesyndication'             => ['q','ref', 'loc'],
    'google'                        => ['q', 'as_q'],
    'googel'                        => ['q'],
    'hotbot.lycos.com'              => ['query'],
    'isearch.com'                   => ['Terms'],
    'local.google'                  => ['q', 'near'],
    'local.yahoo.com'               => ['stx', 'csz' ],
    'looksmart.com'                 => ['key'],
    'lycos'                         => ['query'],
    'maps.google'                   => ['q', 'near'],
    'msntv.msn.com'                 => ['q'],
    'munky.com'                     => ['term'],
    'mysearch.com'                  => ['searchfor'],
    'mywebsearch.com'               => ['searchfor'],
    'mytelus.com'                   => ['q'],
    'netscape.com'                  => ['query'],
    'nextag.com'                    => ['search'],
    'overture.com'                  => ['Keywords'],
    'pricescan.com'                 => ['SearchString'],
    'reviews.search.com'            => ['q'],
    'search.com'                    => ['q'],
    'searchalot.com'                => ['q'],
    'searchfusion.com'              => ['t'],
    'searchon.ca'                   => ['Terms'],
    'search.cnn.com'                => ['query'],
    'search.bearshare.com'          => ['q'],
    'search.comcast.net'            => ['q'],
    'search.dmoz.org'               => ['search'],
    'search.earthlink.net'          => ['q'],
    'search.findsall.info'          => ['s'],
    'search.freeserve.com'          => ['q'],
    'search.freeze.com'             => ['Keywords'],
    'search.go.com'                 => ['search'],
    qr/search\d?.incredimail.com/      => ['q'],
    'search.juno.com'               => ['query'],
    'search.iol.ie'                 => ['q'],
    'search.live.com'               => ['q'],
    'search.netzero.net'            => ['query'],
    'search.*.msn.'                 => ['q'],
    'search.myway.com'              => ['searchfor'],
    'search.opera.com'              => ['search'],
    'search.rogers.com'             => ['qf', 'qo'],
    'search.rr.com'                 => ['qs'],
    'search.start.co.il'            => ['q'],
    'search.starware.com'           => ['qry'],
    'search.sympatico.msn.ca'       => ['q'],
    'search.sweetim.com'            => ['q'],
    'search.usatoday.com'           => ['kw'],
    'search.yahoo.com'              => ['va'],
    'search.virgilio.it'            => ['qs'],
    'search.wanadoo.co.uk'          => ['q'],
    'search.yahoo.com'              => ['q', 'va', 'p'],
    'searchservice.myspace.com'     => ['qry'],
    'shopping.yahoo.com'            => ['p'],
    'start.shaw.ca'                 => ['q'],
    'startgoogle.startpagina.nl'    => ['q'],
    'starware.com'                  => ['qry'],
    'stumbleupon.com'               => ['url'],
    'sucheaol.aol.de'               => ['q'],
    'teoma.com'                     => ['q'],
    'toronto.com'                   => ['query'],
    'trustedsearch.net'             => ['w'],
    'trustedsearch.com'             => ['w'],
    'yahoo'                         => ['p'],
    'yandex.ru'                     => ['text'],
    'youtube.com'                   => ['search_query'],
    'websearch.cbc.ca'              => ['query'],
    'websearch.cs.com'              => ['query'],
    'webtv.net'                     => ['q'],
    'www.bestsearchonearth.info'    => ['Keywords'],
    'www.boat.com'                  => ['HotKeysTopCategory'],
    'www.factbites.com'             => ['kp'],
    'www.mweb.co.za'                => ['q'],
    'www.rr.com/html/search.cfm'    => ['query'],
    'www.wotbox.com'                => ['q'],
);

sub parse_search_string {

    my $self = shift;
    my $url = shift;

    foreach my $engine ( keys %url_regex ) {

        if ( $url =~ $url_regex{$engine} ) {

            # fix funky URLs
            $url = uf_uristr($url);

            my $mech = $self->get_mech();
            eval {
                $mech->get( $url );
            };

            if ( $@ ) {
                warn "Issue with url: $url";
                warn $@;
            }

            if ( $mech->status && $mech->status == 403 ) {
                warn "403 returned for $url  Are you being blocked?";
            }

            if ( $mech->title() ) {
                my $search_term = $self->_apply_regex(
                    string  => $mech->title(),
                    regex   => $engine,
                );

                if ( $search_term ) {
                    $self->{'more'}->{'blame'} = __PACKAGE__;
                    return $search_term;
                }
            }
        }
    }

    my $terms = $self->parse_more( $url );

    if ( $terms ) {
        $self->{'more'}->{'blame'} = __PACKAGE__;
        return $terms;
    }

    # We've come up empty.  Let's see what the superclass can do
    $self->{'more'}->{'blame'} = 'URI::ParseSearchString';
    return $self->SUPER::parse_search_string( $url, @_ );

}

sub se_term {

    my $self = shift;
    return $self->parse_search_string( @_ );

}

sub parse_more {

    my $self    = shift;
    my $url     = shift;

    die "you need to supply at least one argument" unless $url;

    $self->{'more'} = undef;
    $self->{'more'}->{'string'} = $url;

    my $regex = join " | ", $self->_get_engines;
    $self->{'more'}->{'regex'}  = $regex;
    $self->{'more'}->{'url'}    = $url;

    if ( $url =~ m{ ( (?: $regex ) .* ?/ ) .* ?\? (.*)\z }xms ) {

        my $domain       = $1;
        my $query_string = $2;

        # for some reason, escaped quoted strings were messed up under mod_perl
        $query_string   =~ s{&quot;}{"}gxms;
        $query_string   =~ s{&\#39;}{'}gxms;

        my $cgi         = new CGI( $query_string );

        # remove trailing slash
        $domain =~ s{/\z}{};

        my @param_parts = ( );
        my %params      = ( );

        ENGINE:
        foreach my $engine ( $self->_get_engines ) {
            if ( $domain =~ /$engine/i ) {

                my @names = @{ $query_lookup{$engine} };

                $self->{'more'}->{'domain'} = $domain;
                $self->{'more'}->{'names'}  = \@names;

                foreach my $name ( @names ) {
                    push @param_parts, $cgi->param( $name );
                    $params{$name} = $cgi->param( $name );
                }

                last ENGINE;
            }
        }

        my $params = join ( " ", @param_parts );
        my $orig_domain = $domain;
        $domain =~ s/\/.*//g;
        unless ( $domain =~ /\w/ ) {
            $domain = $orig_domain;
        }

        $self->{'more'}->{'terms'} = \@param_parts;
        $self->{'more'}->{'params'} = \%params;

        return $params;
    }

    return;

}

sub blame {

    my $self = shift;
    return $self->{more}->{blame};

}

sub guess {

    my $self    = shift;
    my $url     = shift || $self->{'more'}->{'string'};

    my @guesses = ( 'q', 'query', 'searchfor' );

    if ( $url =~ m{ ( .* ?/ ) .* ?\? (.*)\z }xms ) {

        my $domain       = $1;
        my $query_string = $2;
        my $cgi = new CGI( $query_string );

        foreach my $guess ( @guesses ) {
            if ( $cgi->param( $guess) ) {
                return $cgi->param($guess);
            }
        }
    }

    return;
}

sub set_cached {

    my $self    = shift;
    my $switch  = shift;

    if ( $switch ) {
        $self->{'__more_cached'} = 1;
    }
    else {
        $self->{'__more_cached'} = 0;
    }

    return $self->{'__more_cached'};

}

sub get_cached {

    my $self    = shift;

    return $self->{'__more_cached'};

}

sub get_mech {

    my $self    = shift;
    my $cache   = $self->get_cached;

    if ( $cache ) {

        if ( !exists $self->{'__more_mech_cached'} ) {

            my $mech = WWW::Mechanize::Cached->new();
            $mech->agent("URI::ParseSearchString::More $VERSION");
            $self->{'__more_mech_cached'} = $mech;

        }

        return $self->{'__more_mech_cached'};

    }

    # return a non-caching object
    if ( !exists $self->{'__more_mech'} ) {

        my $mech = WWW::Mechanize->new();
        $mech->agent("URI::ParseSearchString::More $VERSION");
        $self->{'__more_mech'} = $mech;

    }

    return $self->{'__more_mech'};

}

sub _apply_regex {

    my $self    = shift;
    my %rules   = (
        string => { type => SCALAR },
        regex  => { type => SCALAR },
    );

    my %args = validate( @_, \%rules );

    if ( $args{'string'} =~ $search_regex{$args{'regex'}} ) {
        return $1;
    }

    return;
}

sub _get_engines {

    my $lc = List::Compare->new(\@engines, [ keys %query_lookup ]);
    my @remaining_engines = $lc->get_complement;

    my   @all_engines = @engines;
    push @all_engines, @remaining_engines;

    return @all_engines;

}


#################### main pod documentation begin ###################


=head1 NAME

URI::ParseSearchString::More - Extract search strings from more referrers.

=head1 VERSION

Version 0.11

=head1 SYNOPSIS

  use URI::ParseSearchString::More;
  my $more = URI::ParseSearchString::More;
  my $search_terms = $more->se_term( $search_engine_referring_url );


=head1 DESCRIPTION

This module is a subclass of L<URI::ParseSearchString>, so you can call any
methods on this object that you would call on a URI::ParseSearchString object.
This module works a little harder than its SuperClass to get you results. If
it fails, it will return to you the results that L<URI::ParseSearchString>
would have returned to you anyway, so it should function well as a drop-in
replacement.

L<WWW::Mechanize> is used to extract search strings from some URLs
which contain session info rather than search params.  Optionally,
L<WWW::Mechanize::Cached> can be used to cache your lookups. There is additional
parsing and also a guess() method which will return good results in many cases
of doubt.

Repository: L<http://github.com/oalders/uri-parsesearchstring-more/tree/master>


=head1 USAGE

  use URI::ParseSearchString::More;
  my $more = URI::ParseSearchString::More;
  my $search_terms = $more->se_term( $url );


=head1 URI::ParseSearchString

=head2 parse_search_string( $url )

At this point, this is the only "extended" URI::ParseSearchString method.
This method performs the following bit of logic:

1) If the URL supplied looks to be a search query with session info rather
than search data in the URL, it will attempt to access the URL and extract the
search terms from the page returned.

2) If this returns no results, the URL will be processed by parse_more()

3) If there are still no results, the results of URI::ParseSearchString::se_term
will be returned.

WWW::Mechanize::Cached can be used to speed up your movement through large log
files which may contain multiple similar URLs:

  use URI::ParseSearchString::More;
  my $more = URI::ParseSearchString::More;
  $more->set_cached( 1 );
  my $search_terms = $more->se_term( $url );

One interesting thing to note is that maps.google.* URLs have 2 important
params: "q" and "near".   The same can be said for local.google.*  I would
think the results would be incomplete without including the value of "near" in
the search terms for these searches.  So, expect the following results:

  my $url = ""http://local.google.ca/local?sc=1&hl=en&near=Stratford%20ON&btnG=Google%20Search&q=home%20health";
  my $terms = $more->parse_search_string( $url );

  # $terms will = "home health Stratford ON"

Engines with session info currently supported:

  aol.com
  http://as.starware.com/dp/search
  http://as.weatherstudio.com/dp/search

=head2 se_term( $url )

A convenience method which calls parse_search_string.

=head1 URI::ParseSearchString::More

=head2 blame

Returns the name of the module that came up with the results on the last
string parsed by parse_search_string().  Possible results:

  URI::ParseSearchString
  URI::ParseSearchString::More

=head2 set_cached( 0|1 )

Turn caching off and on.  As of version 0.08 caching is OFF by default.  See
KNOWN ISSUES below for more info on this.

=head2 get_cached

Returns 1 if caching is currently on, 0 if it is not.

=head2 get_mech

This gives you direct access to the Mechanize object.  If caching is enabled,
a L<WWW::Mechanize::Cached> object will be returned.  If caching is disabled,
a L<WWW::Mechanize> object will be returned.

If you know what you're doing, play around with it.  Caveat emptor.

  use URI::ParseSearchString::More;
  my $more = URI::ParseSearchString::More;

  my $mech = $more->get_mech();
  $mech->agent("My Agent Name");

  my $search_terms = $more->se_term( $search_engine_referring_url );

=head2 parse_more( $url )

Handles the bulk of More's parsing.  This is automatically called (if needed)
when you pass a search string to se_term().  However, you may also call it
directly.  Just keep in mind that this method will NOT try to get results from
URI::ParseSearchString if it comes up empty.

=head2 guess( $url )

For the most part, the parsing that goes on is done with specific search
engines (ie. the ones that we already know about) in mind.  However, in a lot
cases, a good guess is all that you need.  For example, a URI which contains
a query string with the parameter "q" or "query" is generally the product of
a search.  If se_term() or parse_more() has come up empty, guess may just
provide you with a valid search term.  Then again, it may not.  Caveat emptor.

=head1 TO DO

Here is a list of some of the engines currently not covered by
L<URI::ParseSearchString> that may be added to this module:

  images.google.*
  www.adelphia.net/google/
  http://answers.yahoo.com/question/index;_ylt=Al7fJtDUTm2S69bM0VvjPDIjzKIX?qid=20061214165004AADtB1I

=head1 NOTES

Despite its low version number, this module actually works.  It is,
however, still very young and the interface is subject to some change.

=head1 KNOWN ISSUES

On some systems, this module dies with the following message when caching is
enabled:

Can't store CODE items at blib/lib/Storable.pm (autosplit into blib/lib/auto/Storable/_freeze.al) line 339

For this reason, caching is disabled by default as of version 0.08  If caching
does not fail on your system, I encourage you to enable it.  It seems to me
that this error is not caused by any problem with this module, but I haven't
really spent too much time looking into it as I can't replicate it on my
development machine.  Leaving it enabled by default would cause a lot of
failing tests and switching it off only for tests would mean a lot of passing
tests but failing real world use.

See the documentation it t/005_parse_more.t for information on how to run the
parsing tests with caching enabled.

NOTE: As of 0.11 the $mech->get call is wrapped in an eval.  This gets past the
die problems, even though I still have no idea what the root cause actually is.
So, if you have WWW::Mechanize::Cached installed, you should be able to use the
caching option at this point.

The actual problem may have to do with the following unresolved ticket for
WWW::Mechanize::Cached:

L<http://rt.cpan.org/Public/Bug/Display.html?id=42693>

=head1 BUGS

Please use the RT interface to report bugs:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-ParseSearchString-More>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::ParseSearchString::More

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-ParseSearchString-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-ParseSearchString-More>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-ParseSearchString-More>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-ParseSearchString>

=back

=head1 AUTHOR

    Olaf Alders
    CPAN ID: OALDERS
    WunderCounter.com
    olaf@wundersolutions.com
    http://www.wundercounter.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value
