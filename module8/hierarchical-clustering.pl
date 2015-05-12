#!/usr/bin/env perl

# PODNAME: hierarchical-clustering.pl
# ABSTRACT: Hierarchical Clustering

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-12

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'hierarchical-clustering-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @matrix_rows ) = path($input_file)->lines( { chomp => 1 } );

my $distance_matrix = get_distance_matrix( \@matrix_rows );

my $clusters = hierarchical_clustering( $distance_matrix, $n );

foreach my $cluster ( @{$clusters} ) {
    printf "%s\n", join q{ }, map { $_ + 1 } @{$cluster};
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

# Get clusters by hierarchical clustering
sub hierarchical_clustering {
    my ( $matrix, $n ) = @_;    ## no critic (ProhibitReusedNames)

    my @clusters;

    my $leaves_in_cluster = { map { $_ => [$_] } ( 0 .. $n - 1 ) };
    my $hide = {};

    my $new_node = $n - 1;
    while ( scalar keys %{$hide} < $new_node ) {
        $new_node++;
        my ( $node1, $node2 ) = get_closest_clusters( $matrix, $hide );

        # Hide nodes since now merged in cluster
        $hide->{$node1} = 1;
        $hide->{$node2} = 1;

        # Store most recently merged cluster
        push @clusters,
          [ map { @{ $leaves_in_cluster->{$_} } } ( $node1, $node2 ) ];

        $leaves_in_cluster->{$new_node} = [
            @{ $leaves_in_cluster->{$node1} },
            @{ $leaves_in_cluster->{$node2} }
        ];

        $matrix = add_cluster_to_matrix( $matrix, $hide, $leaves_in_cluster,
            $new_node );
    }

    return \@clusters;
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

    ( $min_node1, $min_node2 ) = sort { $a <=> $b } ( $min_node1, $min_node2 );

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

hierarchical-clustering.pl

Hierarchical Clustering

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements Hierarchical Clustering.

Input: An integer I<n>, followed by an I<n> x I<n> distance matrix.

Output: The result of applying HierarchicalClustering to this distance matrix
(using I<Davg>), with each newly created cluster listed on each line.

=head1 EXAMPLES

    perl hierarchical-clustering.pl

    perl hierarchical-clustering.pl \
        --input_file hierarchical-clustering-extra-input.txt

    diff <(perl hierarchical-clustering.pl) \
        hierarchical-clustering-sample-output.txt

    diff \
        <(perl hierarchical-clustering.pl \
            --input_file hierarchical-clustering-extra-input.txt) \
        hierarchical-clustering-extra-output.txt

    perl hierarchical-clustering.pl --input_file dataset_10934_7.txt \
        > dataset_10934_7_output.txt

=head1 USAGE

    hierarchical-clustering.pl
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
