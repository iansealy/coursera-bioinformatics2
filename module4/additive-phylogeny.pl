#!/usr/bin/env perl

# PODNAME: additive-phylogeny.pl
# ABSTRACT: Additive Phylogeny

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-08

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'additive-phylogeny-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @matrix_rows ) = path($input_file)->lines( { chomp => 1 } );

my $distance_matrix = get_distance_matrix( \@matrix_rows );

my $tree = additive_phylogeny( $distance_matrix, $n );

foreach my $node1 ( sort keys %{$tree} ) {
    foreach my $node2 ( sort keys %{ $tree->{$node1} } ) {
        printf "%d->%d:%d\n", $node1, $node2, $tree->{$node1}{$node2};
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

# Make tree by recursive additive phylogeny
sub additive_phylogeny {
    my ( $matrix, $n ) = @_;    ## no critic (ProhibitReusedNames)

    if ( $n == 2 ) {

        # Base case of tree with single edge
        return {
            0 => { 1 => $matrix->{0}{1} },
            1 => { 0 => $matrix->{1}{0} },
        };
    }

    # Get limb length and trim distance matrix
    my $limb_length = get_limb_length( $n, $matrix );
    foreach my $j ( 0 .. $n - 2 ) {
        $matrix->{$j}{ $n - 1 } -= $limb_length;
        $matrix->{ $n - 1 }{$j} -= $limb_length;
    }

    # Choose i and k
    my ( $i, $k ) = choose_leaves( $matrix, $n );
    my $x = $matrix->{$i}{ $n - 1 };

    ## no critic (ProhibitReusedNames)
    my $tree = additive_phylogeny( $matrix, $n - 1 );
    ## use critic

    # Get path between i and k
    my @path = get_path( $tree, $i, $k );

    # Find where potentially new node (connected to leaf) is on path
    my $node1 = shift @path;    # i
    while (@path) {
        my $node2 = shift @path;
        my $dist = $matrix->{$node1}{$node2} || $tree->{$node1}{$node2};
        if ( $x - $dist == 0 ) {

            # Leaf joined to existing node
            $tree->{$node2}{ $n - 1 } = $limb_length;
            $tree->{ $n - 1 }{$node2} = $limb_length;
            last;
        }
        elsif ( $x - $dist < 0 ) {

            # Leaf joined to new node
            ## no critic (ProhibitMagicNumbers)
            my $v = ( sort { $a <=> $b } keys %{$matrix} )[-1] + 1;
            ## use critic
            while ( exists $tree->{$v} ) {
                $v++;
            }
            $tree->{$node1}{$v} = $x;
            $tree->{$v}{$node1} = $x;
            $tree->{$v}{$node2} = $dist - $x;
            $tree->{$node2}{$v} = $dist - $x;
            delete $tree->{$node1}{$node2};
            delete $tree->{$node2}{$node1};
            $tree->{$v}{ $n - 1 } = $limb_length;
            $tree->{ $n - 1 }{$v} = $limb_length;
            last;
        }
        else {
            $x -= $dist;
        }
        $node1 = $node2;
    }

    return $tree;
}

# Get limb length for specified leaf (and ignore rest of matrix)
sub get_limb_length {
    my ( $j, $matrix ) = @_;

    $j--;    # 1-based to 0-based indexing

    my $min_limb_length;

    foreach my $i ( 0 .. $j - 1 ) {
        foreach my $k ( 0 .. $j - 1 ) {
            my $limb_length =
              ( $matrix->{$i}{$j} + $matrix->{$j}{$k} - $matrix->{$i}{$k} ) / 2;
            if ( !defined $min_limb_length || $limb_length < $min_limb_length )
            {
                $min_limb_length = $limb_length;
            }
        }
    }

    return $min_limb_length;
}

# Choose leaves based on limb length
sub choose_leaves {
    my ( $matrix, $n ) = @_;    ## no critic (ProhibitReusedNames)

    $n--;                       # 1-based to 0-based indexing

    foreach my $i ( 0 .. $n - 1 ) {
        foreach my $k ( 0 .. $n - 1 ) {
            next if $i == $k;
            if ( $matrix->{$i}{$k} == $matrix->{$i}{$n} + $matrix->{$n}{$k} ) {
                return $i, $k;
            }
        }
    }

    return;
}

# Get path between two nodes in a tree by DFS
sub get_path {
    ## no critic (ProhibitReusedNames)
    my ( $tree, $start_node, $end_node, @path ) = @_;
    ## use critic

    push @path, $start_node;

    if ( $start_node == $end_node ) {
        return @path;
    }

    return () if !exists $tree->{$start_node};

    foreach my $node ( keys %{ $tree->{$start_node} } ) {
        my %in_path = map { $_ => 1 } @path;
        if ( !exists $in_path{$node} ) {
            my @new_path = get_path( $tree, $node, $end_node, @path );
            if (@new_path) {
                return @new_path;
            }
        }
    }

    return ();
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

additive-phylogeny.pl

Additive Phylogeny

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements Additive Phylogeny.

Input: An integer I<n> followed by a space-separated I<n> x I<n> distance
matrix.

Output: A weighted adjacency list for the simple tree fitting this matrix.

=head1 EXAMPLES

    perl additive-phylogeny.pl

    perl additive-phylogeny.pl --input_file additive-phylogeny-extra-input.txt

    diff <(perl additive-phylogeny.pl | sort) \
        <(sort additive-phylogeny-sample-output.txt)

    diff \
        <(perl additive-phylogeny.pl \
            --input_file additive-phylogeny-extra-input.txt | sort) \
        <(sort additive-phylogeny-extra-output.txt)

    perl additive-phylogeny.pl --input_file dataset_10330_6.txt \
        > dataset_10330_6_output.txt

=head1 USAGE

    additive-phylogeny.pl
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
