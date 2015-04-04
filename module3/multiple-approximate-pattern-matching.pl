#!/usr/bin/env perl

# PODNAME: multiple-approximate-pattern-matching.pl
# ABSTRACT: Multiple Approximate Pattern Matching

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-04

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Readonly;
use sort 'stable';
use List::MoreUtils qw(uniq);

# Constants
Readonly our $K => 5;    # Subset of suffix array to store
Readonly our $C => 5;    # Subset of counts to keep in checkpoint arrays

# Default options
my $input_file = 'multiple-approximate-pattern-matching-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $text, $patterns, $d ) = path($input_file)->lines( { chomp => 1 } );
$text .= q{$};

my ( $last_col, $first_occurrence, $checkpoint ) =
  index_bwt( make_bwt($text), $C );

my ($partial_array) = make_partial_suffix_array( $text, $K );

my @positions;
foreach my $pattern ( split /\s+/xms, $patterns ) {
    push @positions,
      get_approx_matches( $text, $last_col, $first_occurrence, $checkpoint, $C,
        $partial_array, $pattern, $d );
}

printf "%s\n", join q{ }, sort @positions;

# Make BWT
sub make_bwt {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    my $text_length = length $text;

    ## no critic (ProhibitReusedNames RequireSimpleSortBlock)
    my @positions = sort {
        ## use critic
        my $chr_a;
        my $chr_b;
        my $i = 0;
        while ( $i < length $text ) {
            $chr_a = substr $text, ( $text_length - $a + $i ) % $text_length, 1;
            $chr_b = substr $text, ( $text_length - $b + $i ) % $text_length, 1;
            last if $chr_a ne $chr_b;
            $i++;
        }
        return $chr_a cmp $chr_b;
    } ( 0 .. $text_length - 1 );

    my $bwt = q{};
    foreach my $position (@positions) {
        $bwt .= substr $text, $text_length - 1 - $position, 1;
    }

    return $bwt;
}

# Index BWT
sub index_bwt {
    my ( $bwt, $c ) = @_;

    my @bwt = split //xms, $bwt;

    my $first_occurrence = {};          ## no critic (ProhibitReusedNames)
    my @sorted_bwt       = sort @bwt;
    foreach my $i ( 0 .. ( scalar @sorted_bwt ) - 1 ) {
        if ( !exists $first_occurrence->{ $sorted_bwt[$i] } ) {
            $first_occurrence->{ $sorted_bwt[$i] } = $i;
        }
    }

    my $checkpoint = {};                ## no critic (ProhibitReusedNames)
    my @symbols = keys %{$first_occurrence};
    my %running_checkpoint = map { $_ => 0 } @symbols;
    foreach my $i ( 0 .. ( scalar @bwt ) - 1 ) {
        if ( $i % $c == 0 ) {
            foreach my $symbol (@symbols) {
                $checkpoint->{$symbol}{$i} = $running_checkpoint{$symbol};
            }
        }
        $running_checkpoint{ $bwt[$i] }++;
    }
    if ( scalar @bwt % $c == 0 ) {
        foreach my $symbol (@symbols) {
            $checkpoint->{$symbol}{ scalar @bwt } =
              $running_checkpoint{$symbol};
        }
    }

    return \@bwt, $first_occurrence, $checkpoint;
}

# Make partial suffix array
sub make_partial_suffix_array {
    my ( $text, $k ) = @_;    ## no critic (ProhibitReusedNames)

    my %suffix_at;
    foreach my $i ( 0 .. ( length $text ) - 1 ) {
        $suffix_at{$i} = substr $text, $i;
    }

    my @array = sort { $suffix_at{$a} cmp $suffix_at{$b} } keys %suffix_at;

    my $partial_array = {};    ## no critic (ProhibitReusedNames)
    foreach my $i ( 0 .. ( scalar @array ) - 1 ) {
        if ( $array[$i] % $k == 0 ) {
            $partial_array->{$i} = $array[$i];
        }
    }

    return $partial_array;
}

# Get positions of approximate matches of a pattern
sub get_approx_matches {       ## no critic (ProhibitManyArgs)
    ## no critic (ProhibitReusedNames)
    my ( $text, $last_col, $first_occurrence, $checkpoint, $c, $partial_array,
        $pattern, $d )
      = @_;
    ## use critic

    # Get all seeds
    my $seed_min_length = int( ( length $pattern ) / ( $d + 1 ) );
    my @seeds =
      map { substr $pattern, $_ * $seed_min_length, $seed_min_length }
      ( 0 .. $d - 1 );
    push @seeds, substr $pattern, $d * $seed_min_length;

    # Match each seed
    my @candidate_starts;
    my $seed_start = 0;
    foreach my $seed (@seeds) {
        my @matches =
          get_matches( $last_col, $first_occurrence, $checkpoint, $c,
            $partial_array, $seed );
        @matches = grep { $_ >= 0 } map { $_ - $seed_start } @matches;
        push @candidate_starts, @matches;
        $seed_start += $seed_min_length;
    }

    # Check candidates
    my @starts;
  CANDIDATE: foreach my $candidate_start ( uniq( sort @candidate_starts ) ) {
        my $candidate = substr $text, $candidate_start, length $pattern;
        my $mismatches = 0;
        foreach my $i ( 0 .. ( length $pattern ) - 1 ) {
            if ( ( substr $candidate, $i, 1 ) ne substr $pattern, $i, 1 ) {
                $mismatches++;
            }
            next CANDIDATE if $mismatches > $d;
        }
        if ( $mismatches <= $d ) {
            push @starts, $candidate_start;
        }
    }

    return @starts;
}

# Get positions of matches of a pattern in BWT
sub get_matches {    ## no critic (ProhibitManyArgs)
    ## no critic (ProhibitReusedNames)
    my ( $last_col, $first_occurrence, $checkpoint, $c, $partial_array,
        $pattern )
      = @_;
    ## use critic

    my $top    = 0;
    my $bottom = ( scalar @{$last_col} ) - 1;

    while ( $top <= $bottom ) {
        if ($pattern) {
            ## no critic (ProhibitMagicNumbers)
            my $symbol = substr $pattern, -1, 1, q{};
            ## use critic
            my $top_count =
              count_symbol( $symbol, $top, $last_col, $checkpoint, $c );
            my $bottom_count =
              count_symbol( $symbol, $bottom + 1, $last_col, $checkpoint, $c );
            if ( $top_count < $bottom_count ) {
                $top    = $first_occurrence->{$symbol} + $top_count;
                $bottom = $first_occurrence->{$symbol} + $bottom_count - 1;
            }
            else {
                return ();
            }
        }
        else {
            last;
        }
    }

    my @positions;    ## no critic (ProhibitReusedNames)
    foreach my $pointer ( $top .. $bottom ) {
        my $steps = 0;
        while ( !exists $partial_array->{$pointer} ) {
            $steps++;
            my $count =
              count_symbol( $last_col->[$pointer], $pointer, $last_col,
                $checkpoint, $c );
            $pointer = $first_occurrence->{ $last_col->[$pointer] } + $count;
        }
        push @positions, $partial_array->{$pointer} + $steps;
    }

    return @positions;
}

# Count symbols in portion of array
sub count_symbol {
    ## no critic (ProhibitReusedNames)
    my ( $symbol, $limit, $array, $checkpoint, $c ) = @_;
    ## use critic

    my $base       = int( $limit / $c ) * $c;
    my $base_count = $checkpoint->{$symbol}{$base};
    my $extra_count =
      scalar grep { $_ eq $symbol } @{$array}[ $base .. ( $limit - 1 ) ];

    return $base_count + $extra_count;
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

multiple-approximate-pattern-matching.pl

Multiple Approximate Pattern Matching

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Multiple Approximate Pattern Matching Problem.

Input: A string I<Text>, followed by a collection of strings I<Patterns>, and an
integer I<d>.

Output: All positions where one of the strings in I<Patterns> appears as a
substring of I<Text> with at most I<d> mismatches.

=head1 EXAMPLES

    perl multiple-approximate-pattern-matching.pl

    perl multiple-approximate-pattern-matching.pl \
        --input_file multiple-approximate-pattern-matching-extra-input.txt

    diff <(perl multiple-approximate-pattern-matching.pl) \
        multiple-approximate-pattern-matching-sample-output.txt

    diff <(perl multiple-approximate-pattern-matching.pl \
        --input_file multiple-approximate-pattern-matching-extra-input.txt) \
        multiple-approximate-pattern-matching-extra-output.txt

    perl multiple-approximate-pattern-matching.pl \
        --input_file dataset_304_6.txt > dataset_304_6_output.txt

=head1 USAGE

    multiple-approximate-pattern-matching.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<Text>, followed by a collection of strings
I<Patterns>, and an integer I<d>".

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
