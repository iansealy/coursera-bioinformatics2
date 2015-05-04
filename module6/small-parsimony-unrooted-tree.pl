#!/usr/bin/env perl

# PODNAME: small-parsimony-unrooted-tree.pl
# ABSTRACT: Small Parsimony in an Unrooted Tree

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-02

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use List::Util qw(min max);

# Default options
my $input_file = 'small-parsimony-unrooted-tree-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @adjacency_list ) = path($input_file)->lines( { chomp => 1 } );

my ( $tree, $label ) = make_unrooted_tree( \@adjacency_list );

( $tree, $label ) = make_rooted_tree( $tree, $label );

my $characters = length $label->{0};

my %alphabet;
foreach my $seq ( values %{$label} ) {
    foreach my $symbol ( split //xms, $seq ) {
        $alphabet{$symbol} = 1;
    }
}
my @alphabet = sort keys %alphabet;

my $min_parsimony_score = 0;
my $hamming             = {};
foreach my $character ( 0 .. $characters - 1 ) {
    my $root_parsimony_score;
    ( $root_parsimony_score, $tree, $label, $hamming ) =
      small_parsimony( $tree, $label, $hamming, $character, @alphabet );
    $min_parsimony_score += $root_parsimony_score;
}

# Remove root node from tree
( $tree, $hamming ) = remove_root( $tree, $hamming );

printf "%d\n", $min_parsimony_score;

foreach my $node ( sort keys %{$tree} ) {
    foreach my $child ( @{ $tree->{$node} } ) {
        printf "%s->%s:%d\n", $label->{$node}, $label->{$child},
          $hamming->{$node}{$child} || 0;
        printf "%s->%s:%d\n", $label->{$child}, $label->{$node},
          $hamming->{$node}{$child} || 0;
    }
}

# Make unrooted tree from adjacency list
sub make_unrooted_tree {
    my ($adjacency_list) = @_;

    ## no critic (ProhibitReusedNames)
    my $tree  = {};
    my $label = {};
    ## use critic

    my %seq_to_node;
    my $leaf = 0;
    foreach my $edge ( @{$adjacency_list} ) {
        my ( $node1_or_label, $node2_or_label ) = split /->/xms, $edge;
        if (   $node1_or_label =~ m/\A \d+ \z/xms
            && $node2_or_label =~ m/\A \d+ \z/xms )
        {
            # Edge ends at internal node
            push @{ $tree->{$node1_or_label} }, $node2_or_label;
            $label->{$node1_or_label} = q{};
            $label->{$node2_or_label} = q{};
        }
        elsif ( $node1_or_label =~ m/\A \d+ \z/xms ) {

            # Edge ends at leaf
            my $node;
            if ( !exists $seq_to_node{$node2_or_label} ) {
                $node = $leaf;
                $leaf++;
                $seq_to_node{$node2_or_label} = $node;
            }
            else {
                $node = $seq_to_node{$node2_or_label};
            }

            push @{ $tree->{$node1_or_label} }, $node;
            $label->{$node}           = $node2_or_label;
            $label->{$node1_or_label} = q{};
        }
        else {
            # Edge starts at leaf
            my $node;
            if ( !exists $seq_to_node{$node1_or_label} ) {
                $node = $leaf;
                $leaf++;
                $seq_to_node{$node1_or_label} = $node;
            }
            else {
                $node = $seq_to_node{$node1_or_label};
            }

            push @{ $tree->{$node} }, $node2_or_label;
            $label->{$node}           = $node1_or_label;
            $label->{$node2_or_label} = q{};
        }
    }

    return $tree, $label;
}

# Make rooted tree from unrooted tree
sub make_rooted_tree {
    my ( $unrooted_tree, $label ) = @_;    ## no critic (ProhibitReusedNames)

    my $root = max( keys %{$unrooted_tree} ) + 1;

    # Remove arbitrary edge (including leaf 0) and add root
    my $node1 = 0;
    my $node2 = shift @{ $unrooted_tree->{$node1} };
    @{ $unrooted_tree->{$node2} } =
      grep { $_ != $node1 } @{ $unrooted_tree->{$node2} };
    $unrooted_tree->{$root} = [ $node1, $node2 ];
    $label->{$root} = q{};

    my $tree = {};                         ## no critic (ProhibitReusedNames)
    $tree->{$root} = [];
    my %seen = ( $root => 1 );
    while ( scalar keys %seen < scalar keys %{$unrooted_tree} ) {
        foreach my $node1 ( keys %seen ) {
            foreach my $node2 ( @{ $unrooted_tree->{$node1} } ) {
                next if $seen{$node2};
                push @{ $tree->{$node1} }, $node2;
                $tree->{$node2} = [];
                $seen{$node2} = 1;
            }
        }
    }

    return $tree, $label;
}

# Remove root from tree and replace with edge
sub remove_root {
    my ( $tree, $hamming ) = @_;    ## no critic (ProhibitReusedNames)

    my $root = max( keys %{$tree} );
    my ( $node1, $node2 ) = @{ $tree->{$root} };    # First node is leaf 0
    delete $tree->{$root};
    push @{ $tree->{$node2} }, $node1;

    $hamming->{$node1}{$node2} =
      $hamming->{$root}{$node1} + $hamming->{$root}{$node2};
    $hamming->{$node2}{$node1} =
      $hamming->{$root}{$node1} + $hamming->{$root}{$node2};

    return $tree, $hamming;
}

# Get minimum parsimony score for tree
sub small_parsimony {
    ## no critic (ProhibitReusedNames)
    my ( $tree, $label, $hamming, $character, @alphabet ) = @_;
    ## use critic

    my $tag = {};
    my $s   = {};
    foreach my $node ( keys %{$tree} ) {
        if ( !@{ $tree->{$node} } ) {

            # Leaf
            $tag->{$node} = 1;
            foreach my $k (@alphabet) {
                if ( ( substr $label->{$node}, $character, 1 ) eq $k ) {
                    $s->{$node}{$k} = 0;
                }
                else {
                    $s->{$node}{$k} = undef;    # Infinity
                }
            }
        }
        else {
            # Internal node
            $tag->{$node} = 0;
        }
    }

    my $last_node;
    my $got_ripe = 1;
    while ($got_ripe) {
        $got_ripe = 0;
        foreach my $node ( keys %{$tree} ) {
            next if $tag->{$node} == 1;
            my ( $son, $daughter ) = @{ $tree->{$node} };
            next if $tag->{$son} == 0 || $tag->{$daughter} == 0;

            # Got ripe node
            $got_ripe     = 1;
            $tag->{$node} = 1;
            $last_node    = $node;
            foreach my $k (@alphabet) {
                my ( @son_s, @daughter_s );
                foreach my $i (@alphabet) {
                    my $delta = $i eq $k ? 0 : 1;
                    if ( defined $s->{$son}{$i} ) {
                        push @son_s, $s->{$son}{$i} + $delta;
                    }
                    if ( defined $s->{$daughter}{$i} ) {
                        push @daughter_s, $s->{$daughter}{$i} + $delta;
                    }
                }
                $s->{$node}{$k} = min(@son_s) + min(@daughter_s);
            }
        }
    }

    ( $label, $hamming ) =
      add_symbols( $tree, $label, $hamming, $character, $s, $last_node );

    return min( values %{ $s->{$last_node} } ), $tree, $label, $hamming;
}

# Recursively add symbols to internal nodes of tree
sub add_symbols {    ## no critic (ProhibitManyArgs)
    ## no critic (ProhibitReusedNames)
    my ( $tree, $label, $hamming, $character, $s, $node, $parent_node,
        $parent_symbol )
      = @_;
    ## use critic

    my $min_score = min( values %{ $s->{$node} } );
    my @possible_symbols =
      grep { $s->{$node}{$_} == $min_score } keys %{ $s->{$node} };
    my $symbol;
    if ( scalar @possible_symbols == 1 ) {

        # Only one possible symbol
        $symbol = $possible_symbols[0];
    }
    elsif ( defined $parent_symbol
        && $s->{$node}{$parent_symbol} == $min_score )
    {
        # Multiple possible symbols, so keep same symbol as parent
        $symbol = $parent_symbol;
    }
    else {
        # Arbitrarily choose first symbol
        $symbol = $possible_symbols[0];
    }
    $label->{$node} .= $symbol;
    if ( defined $parent_symbol && $parent_symbol ne $symbol ) {
        $hamming->{$parent_node}{$node}++;
    }

    # Add symbols / Hamming distance to children
    foreach my $child ( @{ $tree->{$node} } ) {
        if ( @{ $tree->{$child} } ) {

            # Internal node
            ( $label, $hamming ) =
              add_symbols( $tree, $label, $hamming, $character, $s, $child,
                $node, $symbol );
        }
        else {
            # Leaf
            if ( ( substr $label->{$child}, $character, 1 ) ne $symbol ) {
                $hamming->{$node}{$child}++;
            }
        }
    }

    return $label, $hamming;
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

small-parsimony-unrooted-tree.pl

Small Parsimony in an Unrooted Tree

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Small Parsimony in an Unrooted Tree Problem.

Input: An integer I<n> followed by an adjacency list for an unrooted binary tree
with I<n> leaves labeled by DNA strings.

Output: The minimum parsimony score of this tree, followed by the adjacency list
of the tree corresponding to labeling internal nodes by DNA strings in order to
minimize the parsimony score of the tree.

=head1 EXAMPLES

    perl small-parsimony-unrooted-tree.pl

    perl small-parsimony-unrooted-tree.pl \
        --input_file small-parsimony-unrooted-tree-extra-input.txt

    diff <(perl small-parsimony-unrooted-tree.pl | sort ) \
        <(sort small-parsimony-unrooted-tree-sample-output.txt)

    diff \
        <(perl small-parsimony-unrooted-tree.pl \
            --input_file small-parsimony-unrooted-tree-extra-input.txt | sort) \
        <(sort small-parsimony-unrooted-tree-extra-output.txt)

    perl small-parsimony-unrooted-tree.pl --input_file dataset_10335_12.txt \
        > dataset_10335_12_output.txt

=head1 USAGE

    small-parsimony-unrooted-tree.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n> followed by an adjacency list for an
unrooted binary tree with I<n> leaves labeled by DNA strings".

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
