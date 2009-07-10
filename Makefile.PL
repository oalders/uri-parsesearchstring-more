

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'URI::ParseSearchString::More',
    VERSION_FROM => 'lib/URI/ParseSearchString/More.pm', # finds \$VERSION
    AUTHOR       => 'Olaf Alders (olaf@wundersolutions.com)',
    ABSTRACT     => 'Extract search strings from more referrers.',
    PREREQ_PM    => {
                     'Config::General'          => 0,
                     'Data::Dumper'             => 0,
                     'File::Spec'               => 0,
                     'List::Compare'            => 0,
                     'Params::Validate'         => 0,
                     'Test::More'               => 0,
                     'Test::Pod'                => 0,
                     'Test::Pod::Coverage'      => 0,
                     'Test::Simple'             => 0.44,
                     'Test::WWW::Mechanize'     => 0,
                     'URI::ParseSearchString'   => 0,
                     'WWW::Mechanize'           => 0,
                     'WWW::Mechanize::Cached'   => 0,
                     'URI::Heuristic'           => 0,
                    },
    LICENSE     => 'perl',
);
