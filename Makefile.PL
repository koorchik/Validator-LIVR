
use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Validator::LIVR',
    AUTHOR           => q{Viktor Turskyi <koorchik@cpan.org>},
    VERSION_FROM     => 'lib/Validator/LIVR.pm',
    ABSTRACT_FROM    => 'lib/Validator/LIVR.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More'      => '0',
        'Test::Exception' => '0',
        'JSON'            => '0'
    },
    PREREQ_PM => {
        'Email::Valid' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Validator-LIVR-*' },
);