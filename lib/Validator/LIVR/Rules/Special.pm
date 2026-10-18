package Validator::LIVR::Rules::Special;

use strict;
use warnings;

use Email::Valid;
use Regexp::Common qw/URI/;

our $VERSION = '2.0';

# Email::Valid is slow. Simple addresses, which it always accepts, are checked with
# this regex first. The local part is up to 64 characters, the address up to 254.
my $SIMPLE_EMAIL_RE = qr/\A
    [a-zA-Z0-9_+-]+ (?: \.[a-zA-Z0-9_+-]+ )*
    \@
    (?: [a-zA-Z0-9] (?: [a-zA-Z0-9-]* [a-zA-Z0-9] )? \. )+
    [a-zA-Z0-9] (?: [a-zA-Z0-9-]* [a-zA-Z0-9] )?
\z/x;

sub email {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return if length($value) <= 254 && index($value, '@') <= 64 && $value =~ $SIMPLE_EMAIL_RE;

        # Email::Valid accepts a trailing line break
        return 'WRONG_EMAIL' if $value =~ /[\r\n\x{2028}\x{2029}]/;
        return 'WRONG_EMAIL' unless Email::Valid->address($value);
        return;
    };
}


sub equal_to_field {
    my $field = shift;

    return sub {
        my ( $value, $params ) = @_;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        return 'FIELDS_NOT_EQUAL' unless defined( $params->{$field} ) && $value eq $params->{$field};
        return;
    };
}


# Every access to %RE makes a new regex object, so it is done once.
# \z, not $: "$" also matches before a trailing newline
my $URL_RE = qr/^$RE{URI}{HTTP}{-scheme => 'https?'}\z/;

sub url {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        $value =~ s/#[^#]*$//;

        return 'WRONG_URL' unless lc($value) =~ $URL_RE;
        return;
    };
}


# \z, not $: "$" also matches before a trailing newline
my $ISO_DATE_RE = qr#^
    (?<year>[0-9]{4})-
    (?<month>[0-1][0-9])-
    (?<day>[0-3][0-9])
\z#x;

sub iso_date {
    return sub {
        my $value = shift;
        return if !defined($value) || $value eq '';
        return 'FORMAT_ERROR' if ref($value);

        if ( $value =~ $ISO_DATE_RE ) {
            my ( $year, $month, $day ) = @+{qw/year month day/};
            return "WRONG_DATE" if $month < 1 || $month > 12;

            my $is_leap_year = ( $year % 4 == 0 && $year % 100 != 0 ) || $year % 400 == 0;
            my $max_day = ( 31, $is_leap_year ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 )[ $month - 1 ];

            return if $day >= 1 && $day <= $max_day;
        }

        return "WRONG_DATE";
    };
}

1;
