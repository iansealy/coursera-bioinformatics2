#!/usr/bin/env perl

# PODNAME: trie-construction.pl
# ABSTRACT: Trie Construction

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-24

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
my $input_file = 'trie-construction-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my @patterns = path($input_file)->lines( { chomp => 1 } );

my $trie = { 0 => undef };    # Root

foreach my $pattern (@patterns) {
    $trie = add_to_trie( $trie, $pattern );
}

printf "%s\n", join "\n", trie_as_triples($trie);

# Add a pattern to a trie
sub add_to_trie {
    my ( $trie, $pattern ) = @_;    ## no critic (ProhibitReusedNames)

    my $current_node = 0;           # Root

    my $new_node = max( keys %{$trie} ) + 1;

    foreach my $symbol ( split //xms, $pattern ) {
        if ( exists $trie->{$current_node}{$symbol} ) {
            $current_node = $trie->{$current_node}{$symbol};
        }
        else {
            $trie->{$current_node}{$symbol} = $new_node;
            $trie->{$new_node}              = undef;
            $current_node                   = $new_node;
            $new_node++;
        }
    }

    return $trie;
}

# Convert trie to list of triples
sub trie_as_triples {
    my ($trie) = @_;    ## no critic (ProhibitReusedNames)

    my @triples;

    foreach my $initial_node ( sort keys %{$trie} ) {
        next if !defined $trie->{$initial_node};    # Skip leaf nodes
        foreach my $symbol ( sort keys %{ $trie->{$initial_node} } ) {
            my $terminal_node = $trie->{$initial_node}{$symbol};
            push @triples, sprintf '%d->%d:%s', $initial_node, $terminal_node,
              $symbol;
        }
    }

    return @triples;
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

trie-construction.pl

Trie Construction

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Trie Construction Problem.

Input: A collection of strings I<Patterns>.

Output: The adjacency list corresponding to I<Trie(Patterns)>, in the following
format. If I<Trie(Patterns)> has I<n> nodes, first label the root with 0 and
then label the remaining nodes with the integers 1 through I<n> - 1 in any order
you like. Each edge of the adjacency list of I<Trie(Patterns)> will be encoded
by a triple: the first two members of the triple must be the integers labeling
the initial and terminal nodes of the edge, respectively; the third member of
the triple must be the symbol labeling the edge.

=head1 EXAMPLES

    perl trie-construction.pl

    perl trie-construction.pl --input_file trie-construction-extra-input.txt

    diff \
        <(perl trie-construction.pl | sort) \
        <(sort trie-construction-sample-output.txt)

    diff \
        <(perl trie-construction.pl \
            --input_file trie-construction-extra-input.txt | sort) \
        <(sort trie-construction-extra-output.txt)

    perl trie-construction.pl --input_file dataset_294_4.txt \
        > dataset_294_4_output.txt

=head1 USAGE

    trie-construction.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A collection of strings I<Patterns>".

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
