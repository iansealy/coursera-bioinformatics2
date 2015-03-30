#!/usr/bin/env perl

# PODNAME: maximal-non-branching-paths.pl
# ABSTRACT: Maximal Non-Branching Paths

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
my $input_file = 'maximal-non-branching-paths-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $graph, $indegree ) = make_graph_and_indegree_from_file($input_file);

my @paths = get_maximal_non_branching_paths( $graph, $indegree );

foreach my $path (@paths) {
    printf "%s\n", join ' -> ', @{$path};
}

# Make graph and get indegrees from adjacency list in a file
sub make_graph_and_indegree_from_file {
    my ($file) = @_;

    my @list = path($file)->lines( { chomp => 1 } );

    ## no critic (ProhibitReusedNames)
    my $graph    = {};
    my $indegree = {};
    ## use critic

    foreach my $pair (@list) {
        my ( $from_node, $to_nodes ) = split /\s -> \s/xms, $pair;
        $indegree->{$from_node} += 0;
        foreach my $to_node ( split /,/xms, $to_nodes ) {
            push @{ $graph->{$from_node} }, $to_node;
            $indegree->{$to_node}++;
        }
    }

    return $graph, $indegree;
}

# Get maximal non-branching paths
sub get_maximal_non_branching_paths {
    my ( $graph, $indegree ) = @_;    ## no critic (ProhibitReusedNames)

    my @paths;                        ## no critic (ProhibitReusedNames)

    my $seen_in_path = {};

    foreach my $node ( sort { $a <=> $b } keys %{$graph} ) {
        next if scalar @{ $graph->{$node} } == 1 && $indegree->{$node} == 1;
        foreach my $next_node ( @{ $graph->{$node} } ) {
            my @path = ( $node, $next_node );
            while (exists $graph->{$next_node}
                && scalar @{ $graph->{$next_node} } == 1
                && $indegree->{$next_node} == 1 )
            {
                $next_node = $graph->{$next_node}->[0];
                push @path, $next_node;
            }
            push @paths, \@path;
            foreach my $seen_node (@path) {
                $seen_in_path->{$seen_node} = 1;
            }
        }
    }

    push @paths, get_isolated_cycles( $graph, $indegree, $seen_in_path );

    return @paths;
}

# Get isolated cycles
sub get_isolated_cycles {
    my ( $graph, $indegree, $seen ) = @_;    ## no critic (ProhibitReusedNames)

    my @paths;                               ## no critic (ProhibitReusedNames)

  NODE: foreach my $node ( sort { $a <=> $b } keys %{$graph} ) {
        next if $seen->{$node};
        next if scalar @{ $graph->{$node} } != 1 || $indegree->{$node} != 1;
        my @path = ($node);
        $seen->{$node} = 1;
        my $next_node = $graph->{$node}->[0];
        while (exists $graph->{$next_node}
            && scalar @{ $graph->{$next_node} } == 1
            && $indegree->{$next_node} == 1 )
        {
            push @path, $next_node;
            if ( $seen->{$next_node} ) {
                push @paths, \@path;
                next NODE;
            }
            $seen->{$next_node} = 1;
            $next_node = $graph->{$next_node}->[0];
        }
    }

    return @paths;
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

maximal-non-branching-paths.pl

Maximal Non-Branching Paths

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Maximal Non-Branching Paths Problem.

Input: The adjacency list of a graph whose nodes are integers.

Output: The collection of all maximal nonbranching paths in this graph.

=head1 EXAMPLES

    perl maximal-non-branching-paths.pl

    perl maximal-non-branching-paths.pl \
        --input_file maximal-non-branching-paths-extra-input.txt

    diff \
        <(perl maximal-non-branching-paths.pl | sort) \
        <(sort maximal-non-branching-paths-sample-output.txt)

    diff \
        <(perl maximal-non-branching-paths.pl \
            --input_file maximal-non-branching-paths-extra-input.txt | sort) \
        <(sort maximal-non-branching-paths-extra-output.txt)

    perl maximal-non-branching-paths.pl --input_file dataset_6207_2.txt \
        > dataset_6207_2_output.txt

=head1 USAGE

    maximal-non-branching-paths.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "The adjacency list of a graph whose nodes are
integers".

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
