use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;

use Validator::LIVR;

my $validator = Validator::LIVR->new({
    code     => 'not_empty',
    password => ['not_empty', { min_length => 3 }],
    address  => { nested_object  => {
        street   => [ 'not_empty', { 'min_length' => 5 } ],
        phones   => {'list_of' => [[ 'not_empty', {'length_equal' => 8} ]]},
        building => [ 'not_empty', 'positive_integer' ]
    } }
}, undef, 'is_clear_undef');

subtest 'Validate data with clearing undefined fields' => sub {
    lives_ok { $validator->prepare() } 'Should build all rules';

    ok( !$validator->validate({
        code     => undef,
        password => undef,
        address  => {
            street   => undef,
            phones   => [ undef, '123', undef ],
            building => 'ERR'
        }
    }), 'should return false due to validation errors for cleared hash of values' );

    is_deeply($validator->get_errors(), {
        address  => {
            phones   => [ 'TOO_SHORT' ],
            building => 'NOT_POSITIVE_INTEGER',
        }
    }, 'Should contain error codes' );
};

subtest 'Validate data with removed undefined fields' => sub {
    lives_ok { $validator->prepare() } 'Should build all rules';

    ok( my $clean_data = $validator->validate({
        code     => undef,
        password => undef,
        address  => {
            street   => undef,
            phones   => [ undef, '12345678', undef ],
            building => '1'
        }
    }), 'Should return clean data' );

    is_deeply($clean_data, {
        address  => {
            phones   => [ '12345678' ],
            building => '1',
        }
    }, 'Should contain cleared data' );
};


done_testing();