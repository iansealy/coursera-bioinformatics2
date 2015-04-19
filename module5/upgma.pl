#!/usr/bin/env perl

# PODNAME: upgma.pl
# ABSTRACT: UPGMA

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-17

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'upgma-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @matrix_rows ) = path($input_file)->lines( { chomp => 1 } );

my $distance_matrix = get_distance_matrix( \@matrix_rows );

my $tree = upgma( $distance_matrix, $n );

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

# Make tree by UPGMA
sub upgma {
    my ( $matrix, $n ) = @_;    ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my $tree = { map { $_ => {} } ( 0 .. $n - 1 ) };
    ## use critic
    my $age = { map { $_ => 0 } ( 0 .. $n - 1 ) };
    my $leaves_in_cluster = { map { $_ => [$_] } ( 0 .. $n - 1 ) };
    my $hide = {};

    my $new_node = $n - 1;
    while ( scalar keys %{$hide} < $new_node ) {
        $new_node++;
        my ( $node1, $node2 ) = get_closest_clusters( $matrix, $hide );
        $tree->{$new_node}{$node1} = 1;
        $tree->{$new_node}{$node2} = 1;
        $tree->{$node1}{$new_node} = 1;
        $tree->{$node2}{$new_node} = 1;
        $age->{$new_node}          = $matrix->{$node1}{$node2} / 2;

        # Hide nodes since now merged in cluster
        $hide->{$node1} = 1;
        $hide->{$node2} = 1;

        $leaves_in_cluster->{$new_node} = [
            @{ $leaves_in_cluster->{$node1} },
            @{ $leaves_in_cluster->{$node2} }
        ];

        $matrix = add_cluster_to_matrix( $matrix, $hide, $leaves_in_cluster,
            $new_node );
    }

    # Add weights
    foreach my $node1 ( keys %{$tree} ) {
        foreach my $node2 ( keys %{ $tree->{$node1} } ) {
            $tree->{$node1}{$node2} = abs $age->{$node1} - $age->{$node2};
        }
    }

    return $tree;
}

# Get closest clusters from matrix
sub get_closest_clusters {
    my ( $matrix, $hide ) = @_;

    my $min_node1;
    my $min_node2;
    my $min_dist;
    foreach my $node1 ( sort keys %{$matrix} ) {
        next if exists $hide->{$node1};
        foreach my $node2 ( sort keys %{ $matrix->{$node1} } ) {
            next if exists $hide->{$node2};
            next if $node1 == $node2;
            my $dist = $matrix->{$node1}{$node2};
            if ( !defined $min_dist || $dist < $min_dist ) {
                $min_dist  = $dist;
                $min_node1 = $node1;
                $min_node2 = $node2;
            }
        }
    }

    return $min_node1, $min_node2;
}

# Add new cluster to distance matrix
sub add_cluster_to_matrix {
    my ( $matrix, $hide, $leaves_in_cluster, $new_cluster ) = @_;

    $matrix->{$new_cluster}{$new_cluster} = 0;
    foreach my $cluster ( keys %{$matrix} ) {
        next if exists $hide->{$cluster};
        next if $cluster == $new_cluster;

        # Get average pairwise distance between all nodes
        my $dist = 0;
        foreach my $node1 ( @{ $leaves_in_cluster->{$new_cluster} } ) {
            foreach my $node2 ( @{ $leaves_in_cluster->{$cluster} } ) {
                $dist += $matrix->{$node1}{$node2};
            }
        }
        my $avg =
          $dist /
          (
            scalar @{ $leaves_in_cluster->{$new_cluster} } *
              scalar @{ $leaves_in_cluster->{$cluster} } );
        $matrix->{$cluster}{$new_cluster} = $avg;
        $matrix->{$new_cluster}{$cluster} = $avg;
    }

    return $matrix;
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

upgma.pl

UPGMA

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements UPGMA.

Input: An integer I<n> followed by a space separated I<n> x I<n> distance
matrix.

Output: An adjacency list for the ultrametric tree returned by UPGMA. Edge
weights should be accurate to three decimal places.

=head1 EXAMPLES

    perl upgma.pl

    perl upgma.pl --input_file upgma-extra-input.txt

    diff <(perl upgma.pl | sort ) <(sort upgma-sample-output.txt)

    diff \
        <(perl upgma.pl --input_file upgma-extra-input.txt | sort) \
        <(sort upgma-extra-output.txt)

    perl upgma.pl --input_file dataset_10332_8.txt > dataset_10332_8_output.txt

=head1 USAGE

    upgma.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n> followed by a space separated I<n> x
I<n> distance matrix".

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
