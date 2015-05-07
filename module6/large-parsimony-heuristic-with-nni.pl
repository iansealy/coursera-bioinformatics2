#!/usr/bin/env perl

# PODNAME: large-parsimony-heuristic-with-nni.pl
# ABSTRACT: Large Parsimony

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

use List::Util qw(min max);
use Storable qw(dclone);

# Default options
my $input_file = 'large-parsimony-heuristic-with-nni-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @adjacency_list ) = path($input_file)->lines( { chomp => 1 } );

my ( $tree, $label ) = make_unrooted_tree( \@adjacency_list );

my $characters = length $label->{0};

my %alphabet;
foreach my $seq ( values %{$label} ) {
    foreach my $symbol ( split //xms, $seq ) {
        $alphabet{$symbol} = 1;
    }
}
my @alphabet = sort keys %alphabet;

# Get score and labeled tree for initial tree
my ( $best_min_parsimony_score, $best_tree, $best_label, $best_hamming ) =
  get_min_parsimony_score_for_tree( dclone($tree), dclone($label), $characters,
    \@alphabet );
display_tree( $best_min_parsimony_score, $best_tree, $best_label, $best_hamming,
    1 );
my $prev_best_min_parsimony_score;

# Try all nearest neighbours until score doesn't improve
while ( !defined $prev_best_min_parsimony_score
    || $best_min_parsimony_score < $prev_best_min_parsimony_score )
{
    $prev_best_min_parsimony_score = $best_min_parsimony_score;

    # Iterate over internal nodes
    my %edge_done;
    foreach my $node1 ( keys %{$tree} ) {
        next if scalar @{ $tree->{$node1} } == 1;
        foreach my $node2 ( @{ $tree->{$node1} } ) {
            next if scalar @{ $tree->{$node2} } == 1;

            # Got internal edge
            next if exists $edge_done{$node2}{$node1};
            $edge_done{$node1}{$node1} = 1;

            # Get score and labeled tree for all nearest neighbours
            my @neighbours = ( dclone($tree) );
            push @neighbours, get_nearest_neighbours( $tree, $node1, $node2 );
            foreach my $neighbour (@neighbours) {
                my ( $new_min_parsimony_score, $new_tree, $new_label,
                    $new_hamming )
                  = get_min_parsimony_score_for_tree( $neighbour,
                    dclone($label), $characters, \@alphabet );
                if ( $new_min_parsimony_score < $best_min_parsimony_score ) {
                    (
                        $best_min_parsimony_score, $best_tree, $best_label,
                        $best_hamming,
                      )
                      = (
                        $new_min_parsimony_score, $new_tree, $new_label,
                        $new_hamming,
                      );
                }
            }
        }
    }
    if ( $best_min_parsimony_score < $prev_best_min_parsimony_score ) {
        display_tree( $best_min_parsimony_score, $best_tree, $best_label,
            $best_hamming );
    }
    $tree = $best_tree;
}

# Get minimum parsimony score for a tree
sub get_min_parsimony_score_for_tree {
    ## no critic (ProhibitReusedNames)
    my ( $tree, $label, $characters, $alphabet ) = @_;
    ## use critic

    ( $tree, $label ) = make_rooted_tree( $tree, $label );

    my $min_parsimony_score = 0;
    my $hamming             = {};
    foreach my $character ( 0 .. $characters - 1 ) {
        my $root_parsimony_score;
        ( $root_parsimony_score, $tree, $label, $hamming ) =
          small_parsimony( $tree, $label, $hamming, $character, @{$alphabet} );
        $min_parsimony_score += $root_parsimony_score;
    }

    # Remove root node from tree
    ( $tree, $hamming ) = remove_root( $tree, $hamming );

    return $min_parsimony_score, $tree, $label, $hamming;
}

# Display tree
sub display_tree {
    ## no critic (ProhibitReusedNames)
    my ( $min_parsimony_score, $tree, $label, $hamming, $first ) = @_;
    ## use critic

    if ( !$first ) {
        print "\n";
    }

    printf "%d\n", $min_parsimony_score;

    foreach my $node ( sort keys %{$tree} ) {
        foreach my $child ( @{ $tree->{$node} } ) {
            printf "%s->%s:%d\n", $label->{$node}, $label->{$child},
              $hamming->{$node}{$child} || 0;
        }
    }

    return;
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

# Remove root from tree and replace with edge and make tree unrooted
sub remove_root {
    my ( $tree, $hamming ) = @_;    ## no critic (ProhibitReusedNames)

    my $root = max( keys %{$tree} );
    my ( $new_edge_node1, $new_edge_node2 ) = @{ $tree->{$root} };

    my $unrooted_tree = {};
    $unrooted_tree->{$new_edge_node1} = [$new_edge_node2];
    $unrooted_tree->{$new_edge_node2} = [$new_edge_node1];
    foreach my $node1 ( keys %{$tree} ) {
        next if $node1 == $root;
        foreach my $node2 ( @{ $tree->{$node1} } ) {
            next if $node2 == $root;
            push @{ $unrooted_tree->{$node1} }, $node2;
            push @{ $unrooted_tree->{$node2} }, $node1;
        }
    }

    $hamming->{$new_edge_node1}{$new_edge_node2} =
      $hamming->{$root}{$new_edge_node1} + $hamming->{$root}{$new_edge_node2};
    $hamming->{$new_edge_node2}{$new_edge_node1} =
      $hamming->{$root}{$new_edge_node1} + $hamming->{$root}{$new_edge_node2};

    return $unrooted_tree, $hamming;
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
        $hamming->{$node}{$parent_node}++;
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
                $hamming->{$child}{$node}++;
            }
        }
    }

    return $label, $hamming;
}

# Get nearest neighbours
sub get_nearest_neighbours {
    my ( $tree, $a, $b ) = @_;    ## no critic (ProhibitReusedNames)

    my $neighbour1 = get_nearest_neighbour( dclone($tree), $a, $b, 1, 0 );
    my $neighbour2 = get_nearest_neighbour( dclone($tree), $a, $b, 1, 1 );

    return $neighbour1, $neighbour2;
}

# Get specific nearest neighbour
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

large-parsimony-heuristic-with-nni.pl

Large Parsimony

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Large Parsimony Problem.

Input: An integer I<n>, followed by an adjacency list for an unrooted binary
tree whose I<n> leaves are labeled by DNA strings and whose internal nodes are
labeled by integers.

Output: The parsimony score and unrooted labeled tree obtained after every step
of the nearest neighbor interchange heuristic. Each step should be separated by
a blank line.

=head1 EXAMPLES

    perl large-parsimony-heuristic-with-nni.pl

    perl large-parsimony-heuristic-with-nni.pl \
        --input_file large-parsimony-heuristic-with-nni-extra-input.txt

    diff <(perl large-parsimony-heuristic-with-nni.pl | sort) \
        <(sort large-parsimony-heuristic-with-nni-sample-output.txt)

    diff \
        <(perl large-parsimony-heuristic-with-nni.pl \
            --input_file large-parsimony-heuristic-with-nni-extra-input.txt \
            | sort) \
        <(sort large-parsimony-heuristic-with-nni-extra-output.txt)

    perl large-parsimony-heuristic-with-nni.pl \
        --input_file dataset_10336_8.txt \
        > dataset_10336_8_output.txt

=head1 USAGE

    large-parsimony-heuristic-with-nni.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n>, followed by an adjacency list for an
unrooted binary tree whose I<n> leaves are labeled by DNA strings and whose
internal nodes are labeled by integers".

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
