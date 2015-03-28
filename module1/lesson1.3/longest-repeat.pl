#!/usr/bin/env perl

# PODNAME: longest-repeat.pl
# ABSTRACT: Longest Repeat

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-28

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use List::Util qw(max);

# Default options
my $input_file = 'longest-repeat-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $text = path($input_file)->slurp;
chomp $text;
$text .= q{$};    # Terminal symbol

my ( $trie, $position, $indegree ) = make_modified_suffix_trie($text);

my ( $tree, $label ) = make_suffix_tree( $trie, $position, $indegree );

printf "%s\n", get_longest_repeat( $tree, $label, $text, 0, q{} );

# Construct modified suffix trie
sub make_modified_suffix_trie {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    ## no critic (ProhibitReusedNames)
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

# Get longest repeat by DFS to find longest sequence before final branch
sub get_longest_repeat {
    ## no critic (ProhibitReusedNames)
    my ( $tree, $label, $text, $node, $seq ) = @_;
    ## use critic

    my @seqs = ($seq);
    foreach my $next_node ( @{ $tree->{$node} } ) {
        if ( ref $tree->{$next_node} eq 'ARRAY' ) {
            my $next_seq = substr $text, $label->{$node}{$next_node}->[0],
              $label->{$node}{$next_node}->[1];
            push @seqs,
              get_longest_repeat( $tree, $label, $text, $next_node,
                $seq . $next_seq );
        }
    }

    return ( reverse sort { length $a <=> length $b } @seqs )[0];
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

longest-repeat.pl

Longest Repeat

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Longest Repeat Problem.

Input: A string I<Text>.

Output: A longest repeat in I<Text>, i.e., a longest substring of I<Text> that
appears in I<Text> more than once.

=head1 EXAMPLES

    perl longest-repeat.pl

    perl longest-repeat.pl --input_file longest-repeat-extra-input.txt

    diff <(perl longest-repeat.pl) longest-repeat-sample-output.txt

    diff \
        <(perl longest-repeat.pl --input_file longest-repeat-extra-input.txt) \
        longest-repeat-extra-output.txt

    perl longest-repeat.pl --input_file dataset_296_5.txt \
        > dataset_296_5_output.txt

=head1 USAGE

    longest-repeat.pl
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
