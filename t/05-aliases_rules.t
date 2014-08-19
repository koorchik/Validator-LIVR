use strict;
use warnings;
use v5.10;
use lib '../lib';

use Test::More;
use Test::Exception;
use Data::Dumper;

use Validator::LIVR;

# my $validator = Validator::LIVR->new({
#     age1 => ['required', 'adult_age'],
#     age2 => ['required', 'adult_age']
# });

# $validator->register_aliased_rule({
#     name  => 'adult_age',
#     rules => ['positive_integer', {min_number => 18}],
#     error => 'WRONG_AGE',
# });

# my $result = $validator->validate({
#     age1 => 20,
#     age2 => 20
# });

# if (!$result) {
#     print Dumper $validator->get_errors();
# } else {
#     print Dumper $result;
# }

Validator::LIVR->register_aliased_default_rule({
    name  => 'adult_age',
    rules => ['positive_integer', {min_number => 18}],
    error => '',
});

Validator::LIVR->register_aliased_default_rule({
    name  => 'address',
    rules => [{nested_object => {
        street => 'required',
        zip    => ['required', 'positive_integer'],
        age    => ['required', 'adult_age'],
    }}],
    error => ''
});

my $validator = Validator::LIVR->new({
    address => ['required', 'address']
});



my $result = $validator->validate({
    address => {
        street => 'AAA',
        zip    => -1,
        age    => 2,
    }
});

if (!$result) {
    print Dumper $validator->get_errors();
} else {
    print Dumper $result;
}

done_testing();