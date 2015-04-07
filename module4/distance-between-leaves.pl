#!/usr/bin/env perl

# PODNAME: distance-between-leaves.pl
# ABSTRACT: Distances Between Leaves

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-07

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'distance-between-leaves-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @adjacency_list ) = path($input_file)->lines( { chomp => 1 } );

my ( $tree, $degree ) = make_tree_from_adjacency_list( \@adjacency_list );

my $distance_matrix = make_distance_matrix( $tree, $degree );

foreach my $leaf_node1 ( sort { $a <=> $b } keys %{$distance_matrix} ) {
    my @distances_row;
    foreach my $leaf_node2 ( sort { $a <=> $b } keys %{$distance_matrix} ) {
        push @distances_row, $distance_matrix->{$leaf_node1}{$leaf_node2};
    }
    printf "%s\n", join q{ }, @distances_row;
}

# Make weighted tree from an adjacency list
sub make_tree_from_adjacency_list {
    my ($adjacency_list) = @_;

    ## no critic (ProhibitReusedNames)
    my $tree   = {};
    my $degree = {};
    ## use critic

    foreach my $edge ( @{$adjacency_list} ) {
        my ( $from_node, $to_node, $weight ) =
          $edge =~ /\A (\d+) -> (\d+) : (\d+) \s*\z/xms;
        $tree->{$from_node}{$to_node} = $weight;
        $degree->{$to_node}++;
    }

    return $tree, $degree;
}

# Make distance matrix from tree
sub make_distance_matrix {
    my ( $tree, $degree ) = @_;    ## no critic (ProhibitReusedNames)

    my $matrix = {};

    foreach my $leaf_node ( keys %{$degree} ) {
        next if $degree->{$leaf_node} > 1;    # Only leaves
        my $visited = {};
        get_distance( $tree, $degree, $matrix, $leaf_node, $leaf_node, 0,
            $visited );
    }

    return $matrix;
}

# Get distances from tree by DFS
sub get_distance {                            ## no critic (ProhibitManyArgs)
    ## no critic (ProhibitReusedNames)
    my ( $tree, $degree, $matrix, $start_node, $node, $dist, $visited ) = @_;
    ## use critic

    $visited->{$node} = 1;

    foreach my $next_node ( keys %{ $tree->{$node} } ) {
        next if exists $visited->{$next_node};
        get_distance( $tree, $degree, $matrix, $start_node, $next_node,
            $dist + $tree->{$node}{$next_node}, $visited );
    }

    if ( $degree->{$node} == 1 ) {
        $matrix->{$start_node}{$node} = $dist;
    }

    return $dist;
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

distance-between-leaves.pl

Distances Between Leaves

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Distances Between Leaves Problem.

Input: An integer I<n> followed by the adjacency list of a weighted tree with
I<n> leaves.

Output: An I<n> x I<n> matrix I<(di,j)>, where I<di,j> is the length of the path
between leaves I<i> and I<j>.

=head1 EXAMPLES

    perl distance-between-leaves.pl

    perl distance-between-leaves.pl \
        --input_file distance-between-leaves-extra-input.txt

    diff \
        <(perl distance-between-leaves.pl) \
        distance-between-leaves-sample-output.txt

    diff \
        <(perl distance-between-leaves.pl \
            --input_file distance-between-leaves-extra-input.txt) \
        distance-between-leaves-extra-output.txt

    perl distance-between-leaves.pl --input_file dataset_10328_11.txt \
        > dataset_10328_11_output.txt

=head1 USAGE

    distance-between-leaves.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n> followed by the adjacency list of a
weighted tree with I<n> leaves".

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
