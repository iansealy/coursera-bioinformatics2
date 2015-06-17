#!/usr/bin/env perl

# PODNAME: probability-of-hidden-path.pl
# ABSTRACT: Probability of a Hidden Path

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-23

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'probability-of-hidden-path-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $path, undef, $states, undef, @matrix ) =
  path($input_file)->lines( { chomp => 1 } );
my @path   = split //xms,    $path;
my @states = split /\s+/xms, $states;

my $transition = get_transitions( \@matrix );

my $probability = get_probability( \@path, $transition );

if ( $probability > 1e-9 ) {    ## no critic (ProhibitMagicNumbers)
    printf "%.15f\n", $probability;
}
else {
    printf "%.11e\n", $probability;
}

# Get transitions from input data
sub get_transitions {
    my ($matrix) = @_;

    my $transition = {};        ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my @states = grep { length $_ } split /\s+/xms, shift @{$matrix};
    ## use critic
    while ( my $line = shift @{$matrix} ) {
        my @fields = split /\s+/xms, $line;
        my $state1 = shift @fields;
        foreach my $state2 (@states) {
            $transition->{$state1}{$state2} = shift @fields;
        }
    }

    # Initial transitions
    foreach my $state (@states) {
        $transition->{q{}}{$state} = 1 / scalar @states;
    }

    return $transition;
}

# Get probability of path
sub get_probability {
    my ( $path, $transition ) = @_;    ## no critic (ProhibitReusedNames)

    my $prob = 1;

    foreach my $i ( 0 .. ( scalar @{$path} ) - 1 ) {
        my $state1 = $i > 0 ? $path->[ $i - 1 ] : q{};
        my $state2 = $path->[$i];
        $prob *= $transition->{$state1}{$state2};
    }

    return $prob;
}

# Get and check command line options
sub get_and_check_options {

    # Get options
    GetOptions(
        'input_file=s' => \$input_file,
        'debug'        => \$debug,
        'help'         => \$help,
        'man'          => \$man,
    ) or pod2usage(2);

    # Documentation
    if ($help) {
        pod2usage(1);
    }
    elsif ($man) {
        pod2usage( -verbose => 2 );
    }

    return;
}

__END__
=pod

=encoding UTF-8

=head1 NAME

probability-of-hidden-path.pl

Probability of a Hidden Path

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Probability of a Hidden Path Problem.

Input: A hidden path I<π> followed by the states I<States> and transition matrix
I<Transition> of an HMM (I<Σ>, I<States>, I<Transition>, I<Emission>).

Output: The probability of this path, Pr(I<π>).

=head1 EXAMPLES

    perl probability-of-hidden-path.pl

    perl probability-of-hidden-path.pl \
        --input_file probability-of-hidden-path-extra-input.txt

    diff <(perl probability-of-hidden-path.pl) \
        probability-of-hidden-path-sample-output.txt

    diff \
        <(perl probability-of-hidden-path.pl \
            --input_file probability-of-hidden-path-extra-input.txt) \
        probability-of-hidden-path-extra-output.txt

    perl probability-of-hidden-path.pl --input_file dataset_11594_2.txt \
        > dataset_11594_2_output.txt

=head1 USAGE

    probability-of-hidden-path.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A hidden path I<π> followed by the states I<States>
and transition matrix I<Transition> of an HMM (I<Σ>, I<States>, I<Transition>,
I<Emission>)".

=item B<--debug>

Print debugging information.

=item B<--help>

Print a brief help message and exit.

=item B<--man>

Print this script's manual page and exit.

=back

=head1 DEPENDENCIES

None

=head1 AUTHOR

=over 4

=item *

Ian Sealy

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Ian Sealy.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
