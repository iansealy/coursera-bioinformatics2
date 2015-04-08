#!/usr/bin/env perl

# PODNAME: limb-length.pl
# ABSTRACT: Limb Length

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-08

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'limb-length-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $n, $j, @matrix_rows ) = path($input_file)->lines( { chomp => 1 } );

my $distance_matrix = get_distance_matrix( \@matrix_rows );

printf "%d\n", get_limb_length( $j, $distance_matrix );

# Get distance matrix from raw matrix rows
sub get_distance_matrix {
    my ($matrix_rows) = @_;

    my $matrix = {};

    my $leaf_node1 = 0;
    foreach my $row ( @{$matrix_rows} ) {
        my $leaf_node2 = 0;
        foreach my $dist ( split /\s+/xms, $row ) {
            $matrix->{$leaf_node1}{$leaf_node2} = $dist;
            $leaf_node2++;
        }
        $leaf_node1++;
    }

    return $matrix;
}

# Get limb length for specified leaf
sub get_limb_length {
    my ( $j, $matrix ) = @_;    ## no critic (ProhibitReusedNames)

    my $n = scalar keys %{$matrix};    ## no critic (ProhibitReusedNames)

    my $min_limb_length;

    foreach my $i ( 0 .. $n - 1 ) {
        next if $i == $j;
        foreach my $k ( 0 .. $n - 1 ) {
            next if $k == $j;
            my $limb_length =
              ( $matrix->{$i}{$j} + $matrix->{$j}{$k} - $matrix->{$i}{$k} ) / 2;
            if ( !defined $min_limb_length || $limb_length < $min_limb_length )
            {
                $min_limb_length = $limb_length;
            }
        }
    }

    return $min_limb_length;
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

limb-length.pl

Limb Length

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Limb Length Problem.

Input: An integer I<n>, followed by an integer I<j> between 0 and I<n>, followed
by a space-separated additive distance matrix I<D> (whose elements are
integers).

Output: The limb length of the leaf in I<Tree(D)> corresponding to the I<j>-th
row of this distance matrix (use 0-based indexing).

=head1 EXAMPLES

    perl limb-length.pl

    perl limb-length.pl --input_file limb-length-extra-input.txt

    diff <(perl limb-length.pl) limb-length-sample-output.txt

    diff \
        <(perl limb-length.pl --input_file limb-length-extra-input.txt) \
        limb-length-extra-output.txt

    perl limb-length.pl --input_file dataset_10329_11.txt \
        > dataset_10329_11_output.txt

=head1 USAGE

    limb-length.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "An integer I<n> followed by the adjacency list of a
weighted tree with I<n> leaves".

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
