#!/usr/bin/env perl

# PODNAME: neighbor-joining.pl
# ABSTRACT: Neighbor Joining

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-19

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use List::Util qw(sum);

# Default options
my $input_file = 'neighbor-joining-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @matrix_rows ) = path($input_file)->lines( { chomp => 1 } );

my $distance_matrix = get_distance_matrix( \@matrix_rows );

my $tree = neighbour_joining( $distance_matrix, $n );

foreach my $node1 ( sort keys %{$tree} ) {
    foreach my $node2 ( sort keys %{ $tree->{$node1} } ) {
        printf "%d->%d:%.3f\n", $node1, $node2, $tree->{$node1}{$node2};
    }
}

# Get distance matrix from raw matrix rows
sub get_distance_matrix {
    my ($matrix_rows) = @_;

    my $matrix = {};

    my $leaf_node1 = 0;
    foreach my $row ( @{$matrix_rows} ) {
        my $leaf_node2 = 0;
        foreach my $dist ( split /\s+/xms, $row ) {
            $matrix->{$leaf_node1}{$leaf_node2} = $dist;
            $leaf_node2++;
        }
        $leaf_node1++;
    }

    return $matrix;
}

# Make tree by neighbour joining
sub neighbour_joining {
    my ( $matrix, $n ) = @_;    ## no critic (ProhibitReusedNames)

    if ( $n == 2 ) {

        # Base case of tree with single edge
        my $node1 = ( sort keys %{$matrix} )[0];
        my $node2 = ( sort keys %{$matrix} )[1];
        return {
            $node1 => { $node2 => $matrix->{$node1}{$node2} },
            $node2 => { $node1 => $matrix->{$node2}{$node1} },
        };
    }

    # Get total distance
    my %total_distance;
    foreach my $node ( sort keys %{$matrix} ) {
        $total_distance{$node} =
          sum( map { $matrix->{$node}{$_} } keys %{ $matrix->{$node} } );
    }

    # Make neighbour joining matrix
    my $neighbour_joining_matrix = {};
    my ( $min_dist, $min_i, $min_j );
    foreach my $i ( sort keys %{$matrix} ) {
        foreach my $j ( sort keys %{$matrix} ) {
            my $dist = 0;
            if ( $i != $j ) {
                $dist =
                  ( $n - 2 ) * $matrix->{$i}{$j} -
                  $total_distance{$i} -
                  $total_distance{$j};
                if ( !defined $min_dist || $dist < $min_dist ) {
                    $min_dist = $dist;
                    $min_i    = $i;
                    $min_j    = $j;
                }
            }
            $neighbour_joining_matrix->{$i}{$j} = $dist;
        }
    }

    my $delta =
      ( $total_distance{$min_i} - $total_distance{$min_j} ) / ( $n - 2 );
    my $limb_length_i = ( $matrix->{$min_i}{$min_j} + $delta ) / 2;
    my $limb_length_j = ( $matrix->{$min_i}{$min_j} - $delta ) / 2;

    # Make new matrix
    my $new_matrix = {};
    ## no critic (ProhibitMagicNumbers)
    my $new_node = ( sort { $a <=> $b } keys %{$matrix} )[-1] + 1;
    ## use critic
    $new_matrix->{$new_node}{$new_node} = 0;
    foreach my $i ( sort keys %{$matrix} ) {
        next if $i == $min_i || $i == $min_j;
        foreach my $j ( sort keys %{$matrix} ) {
            next if $j == $min_i || $j == $min_j;
            $new_matrix->{$i}{$j} = $matrix->{$i}{$j};
        }
        $new_matrix->{$new_node}{$i} =
          ( $matrix->{$i}{$min_i} +
              $matrix->{$i}{$min_j} -
              $matrix->{$min_i}{$min_j} ) / 2;
        $new_matrix->{$i}{$new_node} = $new_matrix->{$new_node}{$i};
    }

    ## no critic (ProhibitReusedNames)
    my $tree = neighbour_joining( $new_matrix, $n - 1 );
    ## use critic

    $tree->{$new_node}{$min_i} = $limb_length_i;
    $tree->{$min_i}{$new_node} = $limb_length_i;
    $tree->{$new_node}{$min_j} = $limb_length_j;
    $tree->{$min_j}{$new_node} = $limb_length_j;

    return $tree;
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

neighbor-joining.pl

Neighbor Joining

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements Neighbor Joining.

Input: An integer I<n>, followed by an I<n> x I<n> distance matrix.

Output: An adjacency list for the tree resulting from applying the
neighbor-joining algorithm.

=head1 EXAMPLES

    perl neighbor-joining.pl

    perl neighbor-joining.pl --input_file neighbor-joining-extra-input.txt

    diff <(perl neighbor-joining.pl | sort) \
        <(sort neighbor-joining-sample-output.txt)

    diff \
        <(perl neighbor-joining.pl \
            --input_file neighbor-joining-extra-input.txt \
            | sort | perl -pe 's/(\.\d+?)0*$/$1/') \
        <(sort neighbor-joining-extra-output.txt)

    perl neighbor-joining.pl --input_file dataset_10333_6.txt \
        > dataset_10333_6_output.txt

=head1 USAGE

    neighbor-joining.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n>, followed by an I<n> x I<n> distance
matrix".

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
