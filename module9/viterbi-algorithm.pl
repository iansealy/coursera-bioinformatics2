#!/usr/bin/env perl

# PODNAME: viterbi-algorithm.pl
# ABSTRACT: Decoding

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
my $input_file = 'viterbi-algorithm-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $emissions, undef, $alphabet, undef, $states, undef, @matrix ) =
  path($input_file)->lines( { chomp => 1 } );
my @emissions = split //xms,    $emissions;
my @alphabet  = split /\s+/xms, $alphabet;
my @states    = split /\s+/xms, $states;

my $transition = get_transitions( \@matrix );
my $emission   = get_emissions( \@matrix );

printf "%s\n", viterbi( $transition, $emission, \@states, \@emissions );

# Get transitions from input data
sub get_transitions {
    my ($matrix) = @_;

    my $transition = {};    ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my @states = grep { length $_ } split /\s+/xms, shift @{$matrix};
    ## use critic
    while ( my $line = shift @{$matrix} ) {
        last if $line eq '--------';
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

# Viterbi algorithm
sub viterbi {
    ## no critic (ProhibitReusedNames)
    my ( $transition, $emission, $states, $emissions ) = @_;
    ## use critic

    my $s         = {};
    my $backtrack = {};
    for my $state ( @{$states} ) {
        $s->{$state}[0] =
          $transition->{q{}}{$state} * $emission->{$state}{ $emissions->[0] };
        $backtrack->{$state}[0] = undef;
    }

    foreach my $i ( 1 .. ( scalar @{$emissions} ) - 1 ) {
        for my $state1 ( @{$states} ) {
            my $max = 0;
            for my $state2 ( @{$states} ) {
                my $product_weight =
                  $s->{$state2}[ $i - 1 ] *
                  $transition->{$state2}{$state1} *
                  $emission->{$state1}{ $emissions->[$i] };
                if ( $product_weight > $max ) {
                    $max = $product_weight;
                    $backtrack->{$state1}[$i] = $state2;
                }
            }
            $s->{$state1}[$i] = $max;
        }
    }

    my @path;
    my $max_product_weight = 0;
    foreach my $state ( @{$states} ) {
        if ( $s->{$state}[-1] > $max_product_weight ) {
            $max_product_weight = $s->{$state}[-1];
            $path[ ( scalar @{$emissions} ) - 1 ] = $state;
        }
    }

    foreach my $i ( reverse 0 .. ( scalar @{$emissions} ) - 2 ) {
        $path[$i] = $backtrack->{ $path[ $i + 1 ] }[ $i + 1 ];
    }

    return join q{}, @path;
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

viterbi-algorithm.pl

Decoding

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Decoding Problem.

Input: A string I<x>, followed by the alphabet from which I<x> was constructed,
followed by the states I<States>, transition matrix I<Transition>, and emission
matrix I<Emission> of an HMM (I<Σ>, I<States>, I<Transition>, I<Emission>).

Output: A path that maximizes the (unconditional) probability Pr(I<x>, I<π>)
over all possible paths I<π>.

=head1 EXAMPLES

    perl viterbi-algorithm.pl

    perl viterbi-algorithm.pl --input_file viterbi-algorithm-extra-input.txt

    diff <(perl viterbi-algorithm.pl) viterbi-algorithm-sample-output.txt

    diff \
        <(perl viterbi-algorithm.pl \
            --input_file viterbi-algorithm-extra-input.txt) \
        viterbi-algorithm-extra-output.txt

    perl viterbi-algorithm.pl --input_file dataset_11594_6.txt \
        > dataset_11594_6_output.txt

=head1 USAGE

    viterbi-algorithm.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<x>, followed by the alphabet from which
I<x> was constructed, followed by the states I<States>, transition matrix
I<Transition>, and emission matrix I<Emission> of an HMM (I<Σ>, I<States>,
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
