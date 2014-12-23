package Validator::LIVR::Rules::String;

use strict;
use warnings;

our $VERSION = '0.08';

sub one_of {
    my $allowed_values;
    if (ref $_[0] eq 'ARRAY') {
        $allowed_values = $_[0];
    } else {
        $allowed_values = [@_];
        pop @$allowed_values; # pop rule_builders
    }


    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'NOT_ALLOWED_VALUE' unless grep { $value eq $_ } @$allowed_values;
        return;
    }
}


sub max_length {
    my $max_length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'TOO_LONG' if length($value) > $max_length;
        return;
    };
}


sub min_length {
    my $min_length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'TOO_SHORT' if length($value) < $min_length;
        return;
    };
}


sub length_equal {
    my $length = shift;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'TOO_SHORT' if length($value) < $length;
        return 'TOO_LONG' if length($value) > $length;
        return;
    };
}


sub length_between {
    my ($min_length, $max_length) = @_;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'TOO_SHORT' if length($value) < $min_length;
        return 'TOO_LONG' if length($value) > $max_length;
        return;
    };
}


sub like {
    my ($re, $flags) = @_;

    my $is_ignore_case = @_ == 3 && index( $flags, 'i') >= 0;
    $re = $is_ignore_case ? qr/$re/i : qr/$re/;

    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';

        return 'WRONG_FORMAT' unless $value =~  m/$re/;
        return;
    };
}

1;