#!/usr/bin/env perl

# PODNAME: shortest-non-shared-substring.pl
# ABSTRACT: Shortest Non-Shared Substring

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-29

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'shortest-non-shared-substring-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my @text = path($input_file)->lines( { chomp => 1 } );

# Terminal symbols
my $text = $text[0] . q{#} . $text[1] . q{$};

my ( $trie, $position, $indegree, $colour ) = make_modified_suffix_trie($text);

my ( $tree, $label ) = make_suffix_tree( $trie, $position, $indegree );

$colour = colour_tree( $tree, $colour );

printf "%s\n",
  get_shortest_non_shared_substring( $tree, $label, $colour, $text, 0, q{} );

# Construct modified suffix trie
sub make_modified_suffix_trie {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    my $colour_switch_i = index $text, q{#};

    ## no critic (ProhibitReusedNames)
    my $trie     = { 0 => undef };    # Root
    my $position = {};
    my $indegree = {};
    my $colour   = {};
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
            $colour->{$current_node} = $i <= $colour_switch_i ? 1 : 2;
        }
    }

    return $trie, $position, $indegree, $colour;
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

# Colour tree
sub colour_tree {
    my ( $tree, $colour ) = @_;    ## no critic (ProhibitReusedNames)

    while ( scalar keys %{$colour} < scalar keys %{$tree} ) {
      NODE: foreach my $node ( keys %{$tree} ) {
            next if exists $colour->{$node};
            my %seen;
            foreach my $next_node ( @{ $tree->{$node} } ) {
                next NODE if !exists $colour->{$next_node};
                $seen{ $colour->{$next_node} } = 1;
            }
            if ( scalar keys %seen > 1 ) {
                $colour->{$node} = 0;
            }
            else {
                $colour->{$node} = ( keys %seen )[0];
            }
        }
    }

    return $colour;
}

# Get shortest non-shared substring by DFS
sub get_shortest_non_shared_substring {    ## no critic (ProhibitManyArgs)
    ## no critic (ProhibitReusedNames)
    my ( $tree, $label, $colour, $text, $node, $seq ) = @_;
    ## use critic

    my @seqs;
    foreach my $next_node ( @{ $tree->{$node} } ) {
        my $next_seq = substr $text, $label->{$node}{$next_node}->[0],
          $label->{$node}{$next_node}->[1];
        if ( $colour->{$next_node} == 1 ) {
            $next_seq = substr $next_seq, 0, 1;
            if ( $next_seq ne q{#} ) {
                push @seqs, $seq . $next_seq;
            }
        }
        elsif ( ref $tree->{$next_node} eq 'ARRAY'
            && $colour->{$next_node} == 0 )
        {
            push @seqs,
              get_shortest_non_shared_substring( $tree, $label, $colour, $text,
                $next_node, $seq . $next_seq );
        }
    }

    return ( sort { length $a <=> length $b } @seqs )[0];
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

shortest-non-shared-substring.pl

Shortest Non-Shared Substring

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Shortest Non-Shared Substring Problem.

Input: Strings I<Text1> and I<Text2>.

Output: The shortest substring of I<Text1> that does not appear in I<Text2>.

=head1 EXAMPLES

    perl shortest-non-shared-substring.pl

    perl shortest-non-shared-substring.pl \
        --input_file shortest-non-shared-substring-extra-input.txt

    diff \
        <(perl shortest-non-shared-substring.pl) \
        shortest-non-shared-substring-sample-output.txt

    diff \
        <(perl shortest-non-shared-substring.pl \
            --input_file shortest-non-shared-substring-extra-input.txt) \
        shortest-non-shared-substring-extra-output.txt

    perl shortest-non-shared-substring.pl --input_file dataset_296_7.txt \
        > dataset_296_7_output.txt

=head1 USAGE

    shortest-non-shared-substring.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "Strings I<Text1> and I<Text2>".

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
