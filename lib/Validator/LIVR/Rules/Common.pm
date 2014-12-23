package Validator::LIVR::Rules::Common;

use strict;
use warnings;

our $VERSION = '0.08';

sub required {
    return sub {
        defined $_[0] && $_[0] ne '' ? undef : 'REQUIRED';
    }
}

sub not_empty {
    return sub {
        ! defined $_[0] || $_[0] ne '' ? undef : "CANNOT_BE_EMPTY"
    };
}

sub not_empty_list {
    sub {
        my $list = shift;
        return 'CANNOT_BE_EMPTY' if !defined($list) || $list eq '';
        return 'WRONG_FORMAT' if ref($list) ne 'ARRAY';
        return 'CANNOT_BE_EMPTY' unless scalar @$list;
        return;
    }
}


1;