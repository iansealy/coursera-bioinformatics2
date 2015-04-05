#!/usr/bin/env perl

# PODNAME: mycoplasma.pl
# ABSTRACT: Multiple Approximate Mycoplasma Pattern Matching

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
use Sort::Naturally;
use List::MoreUtils qw(uniq);

# Constants
Readonly our $C => 5;    # Subset of counts to keep in checkpoint arrays
Readonly our $D => 1;    # Maximum mismatches

# Default options
my $bwt_file                  = 'mycoplasma/myc_bwt.txt';
my $partial_suffix_array_file = 'mycoplasma/myc_psuffarr.txt';
my $reads_file                = 'mycoplasma/myc_reads.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

# Read input files
my ($bwt) = path($bwt_file)->lines( { chomp => 1 } );
my $partial_array = {};
foreach my $line ( path($partial_suffix_array_file)->lines( { chomp => 1 } ) ) {
    my ( $index, $suffix ) = split /,/xms, $line;
    $partial_array->{$index} = $suffix;
}
my @patterns = path($reads_file)->lines( { chomp => 1 } );

my $text = invert_bwt($bwt);

my ( $last_col, $first_occurrence, $checkpoint ) = index_bwt( $bwt, $C );

foreach my $pattern (@patterns) {
    my @positions =
      get_approx_matches( $text, $last_col, $first_occurrence, $checkpoint, $C,
        $partial_array, $pattern, $D );
    if ( scalar @positions ) {
        printf "%s\n", $pattern;
    }
}

# Invert BWT
sub invert_bwt {
    my ($bwt) = @_;    ## no critic (ProhibitReusedNames)

    # Add ordinals
    my %ordinal_of;
    my @bwt;
    foreach my $symbol ( split //xms, $bwt ) {
        my $ordinal = ++$ordinal_of{$symbol};
        push @bwt, $symbol . $ordinal;
    }

    # Sort lexicographically
    my @sorted_bwt = nsort(@bwt);

    # Index BWT
    my %index;
    foreach my $i ( 0 .. ( scalar @bwt ) - 1 ) {
        $index{ $bwt[$i] } = $i;
    }

    # Reconstruct text
    my $text = q{};             ## no critic (ProhibitReusedNames)
    my $pos  = $index{'$1'};    ## no critic (RequireInterpolationOfMetachars)
    while ( length $text < length $bwt ) {
        my $symbol_ordinal = $sorted_bwt[$pos];
        $text .= substr $symbol_ordinal, 0, 1;
        $pos = $index{$symbol_ordinal};
    }

    return $text;
}

# Index BWT
sub index_bwt {
    my ( $bwt, $c ) = @_;       ## no critic (ProhibitReusedNames)

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

# Get positions of approximate matches of a pattern
sub get_approx_matches {    ## no critic (ProhibitManyArgs)
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

    my @positions;
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
        'bwt_file=s'                  => \$bwt_file,
        'partial_suffix_array_file=s' => \$partial_suffix_array_file,
        'reads_file=s'                => \$reads_file,
        'debug'                       => \$debug,
        'help'                        => \$help,
        'man'                         => \$man,
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

mycoplasma.pl

Multiple Approximate Mycoplasma Pattern Matching

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script finds all reads occurring in the genome with at most 1 mismatch.

=head1 EXAMPLES

    perl mycoplasma.pl | wc -l

    perl mycoplasma.pl \
        --bwt_file mycoplasma/myc_bwt.txt \
        --partial_suffix_array_file mycoplasma/myc_psuffarr.txt \
        --reads_file mycoplasma/myc_reads.txt \
        | wc -l

=head1 USAGE

    mycoplasma.pl
        [--bwt_file FILE]
        [--partial_suffix_array_file FILE]
        [--reads_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--bwt_file FILE>

The input file containing the Burrows-Wheeler transform.

=item B<--partial_suffix_array_file FILE>

The input file containing a partial suffix array of the genome.

=item B<--reads_file FILE>

The input file containing a collection of reads.

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
