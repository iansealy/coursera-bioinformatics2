#!/usr/bin/env perl

# PODNAME: probability-of-outcome-given-hidden-path.pl
# ABSTRACT: Probability of an Outcome Given a Hidden Path

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-06-17

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'probability-of-outcome-given-hidden-path-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $emissions, undef, $alphabet, undef, $path, undef, $states, undef,
    @matrix ) = path($input_file)->lines( { chomp => 1 } );
my @emissions = split //xms,    $emissions;
my @alphabet  = split /\s+/xms, $alphabet;
my @path      = split //xms,    $path;
my @states    = split /\s+/xms, $states;

my $emission = get_emissions( \@matrix );

my $probability = get_probability( \@path, \@emissions, $emission );

printf "%.11e\n", $probability;

# Get emissions from input data
sub get_emissions {
    my ($matrix) = @_;

    my $emission = {};    ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my @alphabet = grep { length $_ } split /\s+/xms, shift @{$matrix};
    ## use critic
    while ( my $line = shift @{$matrix} ) {
        my @fields = split /\s+/xms, $line;
        my $state = shift @fields;
        foreach my $letter (@alphabet) {
            $emission->{$state}{$letter} = shift @fields;
        }
    }

    return $emission;
}

# Get probability of emissions given a path
sub get_probability {
    my ( $path, $emissions, $emission ) = @_; ## no critic (ProhibitReusedNames)

    my $prob = 1;

    foreach my $i ( 0 .. ( scalar @{$path} ) - 1 ) {
        $prob *= $emission->{ $path->[$i] }{ $emissions->[$i] };
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

probability-of-outcome-given-hidden-path.pl

Probability of an Outcome Given a Hidden Path

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Probability of an Outcome Given a Hidden Path Problem.

Input: A string I<x>, followed by the alphabet from which I<x> was constructed,
followed by a hidden path I<π>, followed by the states I<States> and emission
matrix I<Emission> of an HMM (I<Σ>, I<States>, I<Transition>, I<Emission>).

Output: The conditional probability Pr(I<x>|I<π>) that I<x> will be emitted
given that the HMM follows the hidden path I<π>.

=head1 EXAMPLES

    perl probability-of-outcome-given-hidden-path.pl

    perl probability-of-outcome-given-hidden-path.pl \
        --input_file probability-of-outcome-given-hidden-path-extra-input.txt

    diff <(perl probability-of-outcome-given-hidden-path.pl) \
        probability-of-outcome-given-hidden-path-sample-output.txt

    diff \
        <(perl probability-of-outcome-given-hidden-path.pl \
            --input_file \
                probability-of-outcome-given-hidden-path-extra-input.txt) \
        probability-of-outcome-given-hidden-path-extra-output.txt

    perl probability-of-outcome-given-hidden-path.pl \
        --input_file dataset_11594_4.txt \
        > dataset_11594_4_output.txt

=head1 USAGE

    probability-of-outcome-given-hidden-path.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<x>, followed by the alphabet from which
I<x> was constructed, followed by a hidden path I<π>, followed by the states
I<States> and emission matrix I<Emission> of an HMM (I<Σ>, I<States>,
I<Transition>, I<Emission>)".

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
