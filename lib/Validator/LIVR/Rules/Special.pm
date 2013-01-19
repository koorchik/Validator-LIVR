package Validator::LIVR::Rules::Special;

use strict;
use warnings;

use Email::Valid;

sub email {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'WRONG_EMAIL' unless Email::Valid->address($value);
        return;
    };
}


sub equal_to_field {
    my $field = shift;

    return sub {
        my ( $value, $params ) = @_;
        return if !defined($value) || $value eq '';

        return 'FIELDS_NOT_EQUAL' unless $value eq $params->{$field};
        return;
    };
}

1;
