#!/usr/bin/env perl

# PODNAME: suffix-tree-construction.pl
# ABSTRACT: Suffix Tree Construction

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-27

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'suffix-tree-construction-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $text = path($input_file)->slurp;
chomp $text;

my ( $trie, $position, $indegree ) = make_modified_suffix_trie($text);

my ( $tree, $label ) = make_suffix_tree( $trie, $position, $indegree );

printf "%s\n", join "\n", get_edge_labels( $text, $label );

# Construct modified suffix trie
sub make_modified_suffix_trie {
    ## no critic (ProhibitReusedNames)
    my ($text) = @_;

    my $trie     = { 0 => undef };    # Root
    my $position = {};
    my $indegree = {};
    ## use critic

    my $new_node = 1;

    foreach my $i ( 0 .. ( length $text ) - 1 ) {
        my $current_node = 0;         # Root
        foreach my $j ( $i .. ( length $text ) - 1 ) {
            my $symbol = substr $text, $j, 1;
            if ( exists $trie->{$current_node}{$symbol} ) {
                $current_node = $trie->{$current_node}{$symbol};
            }
            else {
                $trie->{$current_node}{$symbol}       = $new_node;
                $trie->{$new_node}                    = undef;
                $position->{$current_node}{$new_node} = $j;
                $indegree->{$new_node}++;
                $current_node = $new_node;
                $new_node++;
            }
        }
        if ( !defined $trie->{$current_node} ) {
            $trie->{$current_node} = $i;    # Leaf node
        }

    }

    return $trie, $position, $indegree;
}

# Make suffix tree from modified suffix trie
sub make_suffix_tree {
    my ( $trie, $position, $indegree ) = @_;  ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
    my $tree  = {};
    my $label = {};
    ## use critic

    foreach my $node ( sort { $a <=> $b } keys %{$trie} ) {
        if ( ref $trie->{$node} ne 'HASH' ) {
            $tree->{$node} = $trie->{$node};    # Add leaf node to tree
            next;
        }
        next if scalar keys %{ $trie->{$node} } == 1 && $indegree->{$node} == 1;
        foreach my $symbol ( keys %{ $trie->{$node} } ) {

            # Get non-branching path and add to tree
            my $next_node = $trie->{$node}{$symbol};
            my @path = ( $node, $next_node );
            while (ref $trie->{$next_node} eq 'HASH'
                && scalar keys %{ $trie->{$next_node} } == 1
                && $indegree->{$next_node} == 1 )
            {
                $next_node =
                  $trie->{$next_node}{ ( keys %{ $trie->{$next_node} } )[0] };
                push @path, $next_node;
            }

            # Edge of tree is first and last nodes of path
            push @{ $tree->{ $path[0] } }, $path[-1];

            # Label edge with position and length in text
            $label->{ $path[0] }{ $path[-1] } =
              [ $position->{ $path[0] }{ $path[1] }, scalar @path - 1 ];
        }
    }

    return $tree, $label;
}

# Get edge labels of suffix tree
sub get_edge_labels {
    my ( $text, $label ) = @_;    ## no critic (ProhibitReusedNames)

    my @edge_labels;

    foreach my $node ( sort { $a <=> $b } keys %{$label} ) {
        foreach my $next_node ( sort { $a <=> $b } keys %{ $label->{$node} } ) {
            my ( $pos, $length ) = @{ $label->{$node}{$next_node} };
            push @edge_labels, substr $text, $pos, $length;
        }
    }

    return @edge_labels;
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

suffix-tree-construction.pl

Suffix Tree Construction

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Suffix Tree Construction Problem.

Input: A string I<Text>.

Output: The edge labels of I<SuffixTree(Text)>. You may return these strings in
any order.

=head1 EXAMPLES

    perl suffix-tree-construction.pl

    perl suffix-tree-construction.pl \
        --input_file suffix-tree-construction-extra-input.txt

    diff \
        <(perl suffix-tree-construction.pl | sort) \
        <(sort suffix-tree-construction-sample-output.txt)

    diff \
        <(perl suffix-tree-construction.pl \
            --input_file suffix-tree-construction-extra-input.txt | sort) \
        <(sort suffix-tree-construction-extra-output.txt)

    perl suffix-tree-construction.pl --input_file dataset_296_4.txt \
        > dataset_296_4_output.txt

=head1 USAGE

    suffix-tree-construction.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<Text>".

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
