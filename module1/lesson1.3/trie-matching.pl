#!/usr/bin/env perl

# PODNAME: trie-matching.pl
# ABSTRACT: Trie Matching

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-26

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
my $input_file = 'trie-matching-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my @patterns = path($input_file)->lines( { chomp => 1 } );
my $text = shift @patterns;

my $trie = { 0 => undef };    # Root

foreach my $pattern (@patterns) {
    $trie = add_to_trie( $trie, $pattern );
}

my @positions;
foreach my $position ( 0 .. ( length $text ) - 1 ) {
    if ( prefix_matches_trie( $text, $trie ) ) {
        push @positions, $position;
    }
    substr $text, 0, 1, q{};
}

printf "%s\n", join q{ }, @positions;

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

# Check if trie contains a prefix of input
sub prefix_matches_trie {
    my ( $text, $trie ) = @_;    ## no critic (ProhibitReusedNames)

    my $symbol = substr $text, 0, 1, q{};
    my $node = 0;    # Root of trie

    while (1) {
        if ( !defined $trie->{$node} ) {
            return 1;    # At leaf node
        }
        elsif ( exists $trie->{$node}{$symbol} ) {
            $node = $trie->{$node}{$symbol};
            $symbol = substr $text, 0, 1, q{};
        }
        else {
            return 0;    # No match
        }
    }

    return;
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

trie-matching.pl

Trie Matching

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Multiple Pattern Matching Problem.

Input: A string I<Text> and a collection of strings I<Patterns>.

Output: All starting positions in I<Text> where a string from I<Patterns>
appears as a substring.

=head1 EXAMPLES

    perl trie-matching.pl

    perl trie-matching.pl --input_file trie-matching-extra-input.txt

    diff <(perl trie-matching.pl) trie-matching-sample-output.txt

    diff \
        <(perl trie-matching.pl --input_file trie-matching-extra-input.txt) \
        trie-matching-extra-output.txt

    perl trie-matching.pl --input_file dataset_294_8.txt \
        > dataset_294_8_output.txt

=head1 USAGE

    trie-matching.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<Text> and a collection of strings
I<Patterns>".

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
