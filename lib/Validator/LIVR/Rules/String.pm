package Validator::LIVR::Rules::String;

sub one_of {
    my $values = shift;

    return sub {
        return if !defined($_[0]) || $_[0] eq '';
        return $_[0] ~~ $values ? undef : 'NOT_ALLOWED_VALUE';
    }
}

1;