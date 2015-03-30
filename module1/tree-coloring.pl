#!/usr/bin/env perl

# PODNAME: tree-coloring.pl
# ABSTRACT: Tree Coloring

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
my $input_file = 'tree-coloring-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $tree, $colour ) = make_tree_and_colour_leaves_from_file($input_file);

$colour = colour_tree( $tree, $colour );

foreach my $node ( sort { $a <=> $b } keys %{$colour} ) {
    printf "%d: %s\n", $node, $colour->{$node};
}

# Make tree and colour leaves from adjacency list in a file
sub make_tree_and_colour_leaves_from_file {
    my ($file) = @_;

    my @file = path($file)->lines( { chomp => 1 } );

    my @list    = grep { m/\s -> \s/xms } @file;
    my @colours = grep { m/: \s/xms } @file;

    ## no critic (ProhibitReusedNames)
    my $tree   = {};
    my $colour = {};
    ## use critic

    foreach my $pair (@list) {
        my ( $from_node, $to_nodes ) = split /\s -> \s/xms, $pair;
        foreach my $to_node ( split /,/xms, $to_nodes ) {
            if ( $to_node eq '{}' ) {
                $tree->{$from_node} = undef;    # Leaf node
            }
            else {
                push @{ $tree->{$from_node} }, $to_node;
            }
        }
    }

    foreach my $pair (@colours) {
        my ( $node, $red_or_blue ) = split /: \s/xms, $pair;
        $colour->{$node} = $red_or_blue;
    }

    return $tree, $colour;
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
                $colour->{$node} = 'purple';
            }
            else {
                $colour->{$node} = ( keys %seen )[0];
            }
        }
    }

    return $colour;
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

tree-coloring.pl

Tree Coloring

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Tree Coloring Problem.

Input: An adjacency list, followed by color labels for leaf nodes.

Output: Color labels for all nodes, in any order.

=head1 EXAMPLES

    perl tree-coloring.pl

    perl tree-coloring.pl --input_file tree-coloring-extra-input.txt

    diff \
        <(perl tree-coloring.pl | sort) \
        <(sort tree-coloring-sample-output.txt)

    diff \
        <(perl tree-coloring.pl \
            --input_file tree-coloring-extra-input.txt | sort) \
        <(sort tree-coloring-extra-output.txt)

    perl tree-coloring.pl --input_file dataset_9665_6.txt \
        > dataset_9665_6_output.txt

=head1 USAGE

    tree-coloring.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An adjacency list, followed by color labels for leaf
nodes".

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
