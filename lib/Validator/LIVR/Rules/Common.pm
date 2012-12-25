package Validator::LIVR::Rules::Common;

sub required {
    return sub {
        defined $_[0] && $_[0] ne '' ? undef : 'REQUIRED'
    }
}

sub not_empty {
    return sub {
        ! defined $_[0] || $_[0] ne '' ? undef : "CANNOT_BE_EMPTY"
    };
}




1;