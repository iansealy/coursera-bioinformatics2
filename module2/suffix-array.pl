#!/usr/bin/env perl

# PODNAME: suffix-array.pl
# ABSTRACT: Suffix Array Construction

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-03-31

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

# Default options
my $input_file = 'suffix-array-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $text = path($input_file)->slurp;
chomp $text;

printf "%s\n", join ', ', make_suffix_array($text);

# Make suffix array
sub make_suffix_array {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    my %suffix_at;
    foreach my $i ( 0 .. ( length $text ) - 1 ) {
        $suffix_at{$i} = substr $text, $i;
    }

    my @array = sort { $suffix_at{$a} cmp $suffix_at{$b} } keys %suffix_at;

    return @array;
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

suffix-array.pl

Suffix Array Construction

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Suffix Array Construction Problem.

Input: A string I<Text>.

Output: I<SuffixArray(Text)>.

=head1 EXAMPLES

    perl suffix-array.pl

    perl suffix-array.pl --input_file suffix-array-extra-input.txt

    diff <(perl suffix-array.pl) suffix-array-sample-output.txt

    diff \
        <(perl suffix-array.pl --input_file suffix-array-extra-input.txt) \
        suffix-array-extra-output.txt

    perl suffix-array.pl --input_file dataset_310_2.txt \
        > dataset_310_2_output.txt

=head1 USAGE

    suffix-array.pl
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
