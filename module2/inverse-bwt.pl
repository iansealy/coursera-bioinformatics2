#!/usr/bin/env perl

# PODNAME: inverse-bwt.pl
# ABSTRACT: Inverse Burrows-Wheeler Transform

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-04-01

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Sort::Naturally;

# Default options
my $input_file = 'inverse-bwt-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $bwt = path($input_file)->slurp;
chomp $bwt;

printf "%s\n", invert_bwt($bwt);

# Invert BWT
sub invert_bwt {
    my ($bwt) = @_;    ## no critic (ProhibitReusedNames)

    # Add ordinals
    my %ordinal_of;
    my @bwt;
    foreach my $symbol ( split //xms, $bwt ) {
        my $ordinal = ++$ordinal_of{$symbol};
        push @bwt, $symbol . $ordinal;
    }

    # Sort lexicographically
    my @sorted_bwt = nsort(@bwt);

    # Index BWT
    my %index;
    foreach my $i ( 0 .. ( scalar @bwt ) - 1 ) {
        $index{ $bwt[$i] } = $i;
    }

    # Reconstruct text
    my $text = q{};
    my $pos  = $index{'$1'};    ## no critic (RequireInterpolationOfMetachars)
    while ( length $text < length $bwt ) {
        my $symbol_ordinal = $sorted_bwt[$pos];
        $text .= substr $symbol_ordinal, 0, 1;
        $pos = $index{$symbol_ordinal};
    }

    return $text;
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

inverse-bwt.pl

Inverse Burrows-Wheeler Transform

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Inverse Burrows-Wheeler Transform Problem.

Input: A string I<Transform> (with a single "$" symbol).

Output: The string I<Text> such that I<BWT(Text)> = I<Transform>.

=head1 EXAMPLES

    perl inverse-bwt.pl

    perl inverse-bwt.pl --input_file <(echo 'enwvpeoseu$llt')

    perl inverse-bwt.pl --input_file inverse-bwt-extra-input.txt

    diff <(perl inverse-bwt.pl) inverse-bwt-sample-output.txt

    diff <(perl inverse-bwt.pl \
        --input_file inverse-bwt-extra-input.txt) inverse-bwt-extra-output.txt

    perl inverse-bwt.pl --input_file dataset_299_10.txt \
        > dataset_299_10_output.txt

=head1 USAGE

    inverse-bwt.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<Transform> (with a single "$" symbol)".

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
