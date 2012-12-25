#/usr/v

use v5.10;
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use lib 'lib';

BEGIN {
    use_ok( 'Validator::LIVR' ) || print "Bail out!\n";
}


my $rules = {
    name   => 'required',
    gender => { one_of => [['male', 'female']] },
};


my $data = {
    name    => 'Viktor',
    gender  => 'male',
    garbage => 'garbage'
};

my $validator = Validator::LIVR->new( $rules );
isa_ok( $validator, 'Validator::LIVR' );

my $out = $validator->validate($data);
print Dumper $out;

done_testing();
