package Validator::LIVR::Rules::Filters;

use strict;
use warnings;


sub trim {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';
        
        $$output_ref = $value;
        $$output_ref =~ s/^\s*//;
        $$output_ref =~ s/\s*$//;

        return;
    };
}

sub to_lc {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';
        
        $$output_ref = lc($value);
        return;
    };
}

sub to_uc {
    return sub {
        my ( $value, undef, $output_ref ) = @_;
        return if !defined($value) || ref($value) || $value eq '';
        
        $$output_ref = uc($value);
        return;
    };
}


1;
