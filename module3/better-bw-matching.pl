#!/usr/bin/env perl

# PODNAME: better-bw-matching.pl
# ABSTRACT: Better Burrows-Wheeler Matching

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-02

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use sort 'stable';

# Default options
my $input_file = 'better-bw-matching-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $bwt, $patterns ) = path($input_file)->lines( { chomp => 1 } );

my ( $last_col, $first_occurrence ) = index_bwt($bwt);

my @matches;
foreach my $pattern ( split /\s+/xms, $patterns ) {
    push @matches, count_matches( $last_col, $first_occurrence, $pattern );
}

printf "%s\n", join q{ }, @matches;

# Index BWT
sub index_bwt {
    my ($bwt) = @_;    ## no critic (ProhibitReusedNames)

    my @bwt = split //xms, $bwt;

    my $first_occurrence = {};          ## no critic (ProhibitReusedNames)
    my @sorted_bwt       = sort @bwt;
    foreach my $i ( 0 .. ( scalar @sorted_bwt ) - 1 ) {
        if ( !exists $first_occurrence->{ $sorted_bwt[$i] } ) {
            $first_occurrence->{ $sorted_bwt[$i] } = $i;
        }
    }

    return \@bwt, $first_occurrence;
}

# Count number of matches of a pattern in BWT
sub count_matches {
    ## no critic (ProhibitReusedNames)
    my ( $last_col, $first_occurrence, $pattern ) = @_;
    ## use critic

    my $top    = 0;
    my $bottom = ( scalar @{$last_col} ) - 1;

    while ( $top <= $bottom ) {
        if ($pattern) {
            ## no critic (ProhibitMagicNumbers)
            my $symbol = substr $pattern, -1, 1, q{};
            ## use critic
            my $top_count    = count_symbol( $symbol, $top,        $last_col );
            my $bottom_count = count_symbol( $symbol, $bottom + 1, $last_col );
            if ( $top_count < $bottom_count ) {
                $top    = $first_occurrence->{$symbol} + $top_count;
                $bottom = $first_occurrence->{$symbol} + $bottom_count - 1;
            }
            else {
                return 0;
            }
        }
        else {
            return $bottom - $top + 1;
        }
    }

    return;
}

# Count symbols in portion of array
sub count_symbol {
    my ( $symbol, $limit, $array ) = @_;

    return scalar grep { $_ eq $symbol } @{$array}[ 0 .. ( $limit - 1 ) ];
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

better-bw-matching.pl

Better Burrows-Wheeler Matching

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements Better Burrows-Wheeler Matching.

Input: A string I<BWT(Text)> followed by a collection of strings I<Patterns>.

Output: A list of integers, where the I<i>-th integer corresponds to the number
of substring matches of the I<i>-th member of I<Patterns> in I<Text>.

=head1 EXAMPLES

    perl better-bw-matching.pl

    perl better-bw-matching.pl --input_file better-bw-matching-extra-input.txt

    diff <(perl better-bw-matching.pl) better-bw-matching-sample-output.txt

    diff <(perl better-bw-matching.pl \
        --input_file better-bw-matching-extra-input.txt) \
        better-bw-matching-extra-output.txt

    perl better-bw-matching.pl --input_file dataset_301_7.txt \
        > dataset_301_7_output.txt

=head1 USAGE

    better-bw-matching.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<BWT(Text)> followed by a collection of
strings I<Patterns>".

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
