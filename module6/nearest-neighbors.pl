#!/usr/bin/env perl

# PODNAME: nearest-neighbors.pl
# ABSTRACT: Nearest Neighbors of a Tree

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-03

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Storable qw(dclone);

# Default options
my $input_file = 'nearest-neighbors-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $nodes, @adjacency_list ) = path($input_file)->lines( { chomp => 1 } );

my ( $a, $b ) = split /\s+/xms, $nodes;

my $tree = make_tree( \@adjacency_list );

my ( $neighbour1, $neighbour2 ) = get_nearest_neighbours( $tree, $a, $b );

my $first = 1;
foreach my $neighbour ( $neighbour1, $neighbour2 ) {
    foreach my $node ( sort keys %{$neighbour} ) {
        foreach my $child ( sort @{ $neighbour->{$node} } ) {
            printf "%d->%d\n", $node, $child;
        }
    }
    if ($first) {
        print "\n";
        $first = 0;
    }
}

# Make tree from adjacency list
sub make_tree {
    my ($adjacency_list) = @_;

    my $tree = {};    ## no critic (ProhibitReusedNames)

    foreach my $edge ( @{$adjacency_list} ) {
        my ( $node1, $node2 ) = split /->/xms, $edge;
        push @{ $tree->{$node1} }, $node2;
    }

    return $tree;
}

# Get nearest neighbours
sub get_nearest_neighbours {
    my ( $tree, $a, $b ) = @_;    ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my $neighbour1 = get_nearest_neighbour( dclone($tree), $a, $b, 1, 0 );
    my $neighbour2 = get_nearest_neighbour( dclone($tree), $a, $b, 1, 1 );
    ## use critic

    return $neighbour1, $neighbour2;
}

sub get_nearest_neighbour {
    ## no critic (ProhibitReusedNames)
    my ( $tree, $a, $b, $which_a, $which_b ) = @_;
    ## use critic

    my $x = ( grep { $_ != $b } @{ $tree->{$a} } )[$which_a];
    my $y = ( grep { $_ != $a } @{ $tree->{$b} } )[$which_b];

    # Delete edges (a, x) and (b, y)
    @{ $tree->{$a} } = grep { $_ != $x } @{ $tree->{$a} };
    @{ $tree->{$x} } = grep { $_ != $a } @{ $tree->{$x} };
    @{ $tree->{$b} } = grep { $_ != $y } @{ $tree->{$b} };
    @{ $tree->{$y} } = grep { $_ != $b } @{ $tree->{$y} };

    # Add edges (a, y) and (b, x)
    push @{ $tree->{$a} }, $y;
    push @{ $tree->{$y} }, $a;
    push @{ $tree->{$b} }, $x;
    push @{ $tree->{$x} }, $b;

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

nearest-neighbors.pl

Nearest Neighbors of a Tree

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Nearest Neighbors of a Tree Problem.

Input: Two internal nodes I<a> and I<b> specifying an edge I<e>, followed by an
adjacency list of an unrooted binary tree.

Output: Two adjacency lists representing the nearest neighbors of the tree with
respect to I<e>. Separate the adjacency lists with a blank line.

=head1 EXAMPLES

    perl nearest-neighbors.pl

    perl nearest-neighbors.pl --input_file nearest-neighbors-extra-input.txt

    diff <(perl nearest-neighbors.pl | sort ) \
        <(sort nearest-neighbors-sample-output.txt)

    diff \
        <(perl nearest-neighbors.pl \
            --input_file nearest-neighbors-extra-input.txt | sort) \
        <(sort nearest-neighbors-extra-output.txt)

    perl nearest-neighbors.pl --input_file dataset_10336_6.txt \
        > dataset_10336_6_output.txt

=head1 USAGE

    nearest-neighbors.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "Two internal nodes I<a> and I<b> specifying an edge
I<e>, followed by an adjacency list of an unrooted binary tree".

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
