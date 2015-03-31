#!/usr/bin/env perl

# PODNAME: bwt.pl
# ABSTRACT: Burrows-Wheeler Transform Construction

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

use List::Util qw(max);

# Default options
my $input_file = 'bwt-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $text = path($input_file)->slurp;
chomp $text;

printf "%s\n", join ', ', make_bwt($text);

# Make BWT
sub make_bwt {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    my @matrix = ($text);
    foreach ( 2 .. length $text ) {
        ## no critic (ProhibitMagicNumbers)
        my $last_chr = substr $text, -1, 1, q{};
        ## use critic
        $text = $last_chr . $text;
        push @matrix, $text;
    }

    @matrix = sort @matrix;

    ## no critic (ProhibitMagicNumbers)
    my $bwt = join q{}, map { substr $_, -1, 1 } @matrix;
    ## use critic

    return $bwt;
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

bwt.pl

Burrows-Wheeler Transform Construction

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Burrows-Wheeler Transform Construction Problem.

Input: A string I<Text>.

Output: I<BWT(Text)>.

=head1 EXAMPLES

    perl bwt.pl

    perl bwt.pl --input_file bwt-extra-input.txt

    diff <(perl bwt.pl) bwt-sample-output.txt

    diff <(perl bwt.pl --input_file bwt-extra-input.txt) bwt-extra-output.txt

    perl bwt.pl --input_file dataset_297_4.txt > dataset_297_4_output.txt

=head1 USAGE

    bwt.pl
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
