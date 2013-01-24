package Validator::LIVR;

use v5.10;
use strict;
use warnings FATAL => 'all';

use Validator::LIVR::Rules::Common;
use Validator::LIVR::Rules::String;
use Validator::LIVR::Rules::Numeric;
use Validator::LIVR::Rules::Special;
use Validator::LIVR::Rules::Helpers;

our $VERSION = '0.01';

our %DEFAULT_RULES = (
    'required'         => \&Validator::LIVR::Rules::Common::required,
    'not_empty'        => \&Validator::LIVR::Rules::Common::not_empty,

    'one_of'           => \&Validator::LIVR::Rules::String::one_of,
    'min_length'       => \&Validator::LIVR::Rules::String::min_length,
    'max_length'       => \&Validator::LIVR::Rules::String::max_length,
    'length_equal'     => \&Validator::LIVR::Rules::String::length_equal,
    'length_between'   => \&Validator::LIVR::Rules::String::length_between,
    'like'             => \&Validator::LIVR::Rules::String::like,

    'integer'          => \&Validator::LIVR::Rules::Numeric::integer,
    'positive_integer' => \&Validator::LIVR::Rules::Numeric::positive_integer,
    'decimal'          => \&Validator::LIVR::Rules::Numeric::decimal,
    'positive_decimal' => \&Validator::LIVR::Rules::Numeric::positive_decimal,
    'max_number'       => \&Validator::LIVR::Rules::Numeric::max_number,
    'min_number'       => \&Validator::LIVR::Rules::Numeric::min_number,
    'number_between'   => \&Validator::LIVR::Rules::Numeric::number_between,

    'email'            => \&Validator::LIVR::Rules::Special::email,
    'equal_to_field'   => \&Validator::LIVR::Rules::Special::equal_to_field,

    'nested_object'    => \&Validator::LIVR::Rules::Helpers::nested_object,
    'list_of'          => \&Validator::LIVR::Rules::Helpers::list_of,
    'list_of_objects'  => \&Validator::LIVR::Rules::Helpers::list_of_objects,
    'list_of_different_objects' => \&Validator::LIVR::Rules::Helpers::list_of_different_objects,
);

sub new {
    my ($class, $livr_rules) = @_;

    my $self = bless {
        is_prepared        => 0,
        livr_rules         => $livr_rules,
        validators         => {},
        validator_builders => {},
        errors             => undef,
    }, $class;

    $self->{validator_builders} = { %DEFAULT_RULES };

    return $self;
}

sub register_rules {
    my $class = shift;
    %DEFAULT_RULES = { %DEFAULT_RULES, @_  };
}

sub prepare {
    my $self = shift;
    $self->{is_prepared} = 1;

    my $all_rules = $self->{livr_rules};

    while ( my ($field, $field_rules) = each %$all_rules ) {
        $field_rules = [$field_rules] if ref($field_rules) ne 'ARRAY';

        my @validators;
        foreach my $rule (@$field_rules) {
            my ($name, $args) = $self->_parse_rule($rule);
            push @validators, $self->_build_validator($name, $args);
        }
        $self->{validators}{$field} = \@validators;
    }
}

sub validate {
    my ($self, $data) = @_;
    $self->prepare() unless $self->{is_prepared};

    if ( ref($data) ne 'HASH' ) {
        $self->{errors} = 'FORMAT_ERROR';
        return;
    }

    my ( %errors, %result );

    foreach my $field_name ( keys %{ $self->{validators} } ) {
        my $validators = $self->{validators}{$field_name};
        next unless $validators && @$validators;

        my $value = $data->{$field_name};

        my $is_ok = 1;
        my $field_result;

        foreach my $v_cb (@$validators) {
            undef($field_result);
            my $err_code = $v_cb->($value, $data, \$field_result);

            if ( $err_code ) {
                $errors{$field_name} = $err_code;
                $is_ok = 0;
                last;
            }
        }

        if ( $is_ok && exists $data->{$field_name} ) {
            $result{$field_name} = $field_result // $value;
        }
    }

    if ( keys %errors ) {
        $self->{errors} = \%errors;
        return;
    } else {
        $self->{errors} = undef;
        return \%result;
    }
}

sub get_errors {
    my $self = shift;
    return $self->{errors};
}

sub _parse_rule {
    my ($self, $livr_rule) = @_;

    my ($name, $args);

    if ( ref($livr_rule) eq 'HASH' ) {
        ($name) = keys %$livr_rule;

        $args = $livr_rule->{$name};
        $args = [$args] unless ref($args) eq 'ARRAY';
    } else {
        $name = $livr_rule;
        $args = [];
    }

    return ($name, $args);
}

sub _build_validator {
    my ($self, $name, $args) = @_;
    die "Rule [$name] not registered\n" unless $self->{validator_builders}->{$name};

    return $self->{validator_builders}->{$name}->(@$args);
}



=head1 NAME

Validator::LIVR - Lightweight validator supporting Language Independent Validation Rules Specification (LIVR)

=head1 SYNOPSIS

    use Validator::LIVR;

    my $validator = Validator::LIVR->new({
        name      => 'required',
        email     => [ 'required', 'email' ],
        gender    => { one_of => [['male', 'female']] },
        phone     => { max_length => 10 },
        password  => [ 'required', {min_length => 10} ],
        password2 => { equal_to_field => 'password' }
     });

     if ( my $valid_data = $validator->validate($user_data) ) {
        save_user($valid_data);
     } else {
        my $errors = $validator->get_errors();
        ...
     }

=head1 DESCRIPTION

L<Validator::LIVR> is a L<Mojolicious> plugin that adds "render_file" helper. It does not read file in memory and just streaming it to a client.

See L<https://github.com/koorchik/LIVR> for details.

Features:

=over 4

=item * Rules are declarative and language independent

=item * Any number of rules for each field

=item * Return together errors for all fields

=item * Excludes all fields that do not have validation rules described

=item * Has possibility to validatate complex hierarchical structures

=item * Easy to describe and undersand rules

=item * Returns understandable error codes(not error messages)

=item * Easy to add own rules

=item * Multipurpose (user input validation, configs validation, contracts programming etc)

=back

=head1 CLASS METHODS

=head2 Validator::LIVR->new( $LIVR )

Contructor creates validator objects.

$LIVR - validations rules. Rules description is available here - L<https://github.com/koorchik/LIVR>

=head2 Validator::LIVR->register_rules( RULE_NAME => \&RULE_BUILDER)

&RULE_BUILDER - is a subtorutine reference which will be called for building single rule validator.


    Validator::LIVR->register_rules( my_rule => sub {
        my ($arg1, $arg2, $arg3) =  @_;

        return sub {
            my ( $value, $all_values, $output_ref ) = @_;
            
            if ($not_valid) {
                return "SOME_ERROR_CODE"    
            }
            else {
                
            }
            
        }
    });

Then you can use "my_rule" for validation:
    
    {
        name1 => 'my_rule' # Call without parameters
        name2 => { 'my_rule' => $arg1 } # Call with one parameter.
        name3 => { 'my_rule' => [$arg1] } # Call with one parameter.
        name4 => { 'my_rule' => [ $arg1, $arg2, $arg3 ] } # Call with many parameters.
    }


Here is "max_number" implemenation:

    sub max_number {
        my $max_number = shift;
        
        return sub {
            my $value = shift;

            # We do not validate empty fields. We have "required" rule for this purpose
            return if !defined($value) || $value eq ''; 

            return 'TOO_HIGH' if $value > $max_number; # Return error message
            return; # returning undef means that there was no errors;
        };
    }

    Validator::LIVR->register_rules( max_number => \&max_number );

All rules for the validator are equal. It does not distinguish "required" and "list_of_different_objects" rule.
So, you can extend validator with any rules you like.

Just look at the existing rules implementation:

=over 4

=item * L<Validator::LIVR::Rules::Common>

=item * L<Validator::LIVR::Rules::String>;

=item * L<Validator::LIVR::Rules::Numeric>;

=item * L<Validator::LIVR::Rules::Special>;

=item * L<Validator::LIVR::Rules::Helpers>;

=back

All rules description is available here - L<https://github.com/koorchik/LIVR>

=head1 OBJECT METHODS

=head2 $VALIDATOR->validate(\%INPUT)

Validates user input. On success returns $VALID_DATA (contains only data that has described validation rules). On error return false. 

    my $VALID_DATA = $VALIDATOR->validate(\%INPUT)

    if ($VALID_DATA) {
        
    } else {
        my $errors = $VALIDATOR->get_errors();
    }

=head2 $VALIDATOR->get_errors( )

Returns errors hash.

    {
        "field1" => "ERROR_CODE",
        "field2" => "ERROR_CODE",
        ...
    }

For example:

    {
        "country"  => "NOT_ALLOWED_VALUE",
        "zip"      => "NOT_POSITIVE_INTEGER",
        "street":  => "REQUIRED",
        "building" => "NOT_POSITIVE_INTEGER"
    },    


=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Validator-LIVR>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::LIVR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-LIVR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-LIVR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-LIVR>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-LIVR/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Viktor Turskyi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Validator::LIVR