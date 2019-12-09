use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

my $data = {
    valid => 1,
    extra => 1
};

my $rules = {
    valid => 'required'
};


subtest 'Validate data with DEFAULT_STRICT' => sub {
    Validator::LIVR->default_strict(1);
    my $validator = Validator::LIVR->new($rules);
    my $output = $validator->validate($data);

    ok( !$output, 'Validation fails' );

    is_deeply($validator->get_errors(), {
        extra     =>'EXTRA_FIELD'
    }, 'Should contain error codes' );
};

subtest 'Validate data with DEFAULT_STRICT set back to 0' => sub {
    Validator::LIVR->default_strict(0);

    my $validator = Validator::LIVR->new($rules);
    my $output = $validator->validate($data);

    is_deeply( $output, {
            valid => 1
        }, 'Validation succeeds' );

    ok( !$validator->get_errors(), 'Should NOT contain error codes' );
};

subtest 'Validate data with IS_STRICT set by the constructor' => sub {

    my $validator = Validator::LIVR->new($rules, undef, 1);
    my $output = $validator->validate($data);

    ok( !$output, 'Validation fails' );

    is_deeply($validator->get_errors(), {
        extra     =>'EXTRA_FIELD'
    }, 'Should contain error codes' );
};

done_testing();
