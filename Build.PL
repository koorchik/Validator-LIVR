use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Validator::LIVR',
    license             => 'Artistic_2_0',
    dist_author         => q{Viktor Turskyi <koorchik@cpan.org>},
    dist_version_from   => 'lib/Validator/LIVR.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'JSON'            => 0,
        'Test::Exception' => 0,
    },
    requires => {
        'Email::Valid' => 0,
    },
    add_to_cleanup     => [ 'Validator-LIVR-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
