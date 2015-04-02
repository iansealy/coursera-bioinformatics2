#!/usr/bin/env perl

# PODNAME: partial-suffix-array.pl
# ABSTRACT: Partial Suffix Array Construction

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-02

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'partial-suffix-array-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $text, $k ) = path($input_file)->lines( { chomp => 1 } );

my ( $index, $partial_array ) = make_partial_suffix_array( $text, $k );

foreach my $i ( 0 .. ( scalar @{$index} ) - 1 ) {
    printf "%d,%d\n", $index->[$i], $partial_array->[$i];
}

# Make partial suffix array
sub make_partial_suffix_array {
    my ( $text, $k ) = @_;    ## no critic (ProhibitReusedNames)

    my %suffix_at;
    foreach my $i ( 0 .. ( length $text ) - 1 ) {
        $suffix_at{$i} = substr $text, $i;
    }

    my @array = sort { $suffix_at{$a} cmp $suffix_at{$b} } keys %suffix_at;

    my @index;
    my @partial_array;
    foreach my $i ( 0 .. ( scalar @array ) - 1 ) {
        if ( $array[$i] % $k == 0 ) {
            push @index,         $i;
            push @partial_array, $array[$i];
        }
    }

    return \@index, \@partial_array;
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

partial-suffix-array.pl

Partial Suffix Array Construction

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Partial Suffix Array Construction Problem.

Input: A string I<Text> and a positive integer I<K>.

Output: I<SuffixArrayK(Text)>, in the form of a list of ordered pairs
(i, I<SuffixArray(i)>) for all nonempty entries in the partial suffix array.

=head1 EXAMPLES

    perl partial-suffix-array.pl

    perl partial-suffix-array.pl \
        --input_file partial-suffix-array-extra-input.txt

    diff <(perl partial-suffix-array.pl) partial-suffix-array-sample-output.txt

    diff \
        <(perl partial-suffix-array.pl \
            --input_file partial-suffix-array-extra-input.txt) \
        partial-suffix-array-extra-output.txt

    perl partial-suffix-array.pl --input_file dataset_9809_2.txt \
        > dataset_9809_2_output.txt

=head1 USAGE

    partial-suffix-array.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<Text> and a positive integer I<K>".

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
