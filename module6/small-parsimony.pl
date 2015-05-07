#!/usr/bin/env perl

# PODNAME: small-parsimony.pl
# ABSTRACT: Small Parsimony

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-30

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use List::Util qw(min);

# Default options
my $input_file = 'small-parsimony-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, @adjacency_list ) = path($input_file)->lines( { chomp => 1 } );

my ( $tree, $label ) = make_tree( \@adjacency_list );

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

printf "%d\n", $min_parsimony_score;

foreach my $node ( sort keys %{$tree} ) {
    foreach my $child ( @{ $tree->{$node} } ) {
        printf "%s->%s:%d\n", $label->{$node}, $label->{$child},
          $hamming->{$node}{$child} || 0;
        printf "%s->%s:%d\n", $label->{$child}, $label->{$node},
          $hamming->{$node}{$child} || 0;
    }
}

# Make tree from adjacency list
sub make_tree {
    my ($adjacency_list) = @_;

    ## no critic (ProhibitReusedNames)
    my $tree  = {};
    my $label = {};
    ## use critic

    my $leaf = 0;
    foreach my $edge ( @{$adjacency_list} ) {
        my ( $node1, $node2_or_label ) = split /->/xms, $edge;
        if ( $node2_or_label =~ m/\A \d+ \z/xms ) {

            # Edge ends at internal node
            push @{ $tree->{$node1} }, $node2_or_label;    # Node 2
            $label->{$node1}          = q{};
            $label->{$node2_or_label} = q{};
        }
        else {
            # Edge ends at leaf
            push @{ $tree->{$node1} }, $leaf;
            $tree->{$leaf}   = [];
            $label->{$leaf}  = $node2_or_label;            # Label
            $label->{$node1} = q{};
            $leaf++;
        }
    }

    return $tree, $label;
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

small-parsimony.pl

Small Parsimony

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Small Parsimony Problem.

Input: An integer I<n> followed by an adjacency list for a rooted binary tree
with I<n> leaves labeled by DNA strings.

Output: The minimum parsimony score of this tree, followed by the adjacency list
of the tree corresponding to labeling internal nodes by DNA strings in order to
minimize the parsimony score of the tree.

=head1 EXAMPLES

    perl small-parsimony.pl

    perl small-parsimony.pl --input_file small-parsimony-extra-input.txt

    diff <(perl small-parsimony.pl | sort) \
        <(sort small-parsimony-sample-output.txt)

    diff \
        <(perl small-parsimony.pl \
            --input_file small-parsimony-extra-input.txt | sort) \
        <(sort small-parsimony-extra-output.txt)

    perl small-parsimony.pl --input_file dataset_10335_10.txt \
        > dataset_10335_10_output.txt

=head1 USAGE

    small-parsimony.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n> followed by an adjacency list for a
rooted binary tree with I<n> leaves labeled by DNA strings".

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
