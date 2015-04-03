#!/usr/bin/env perl

# PODNAME: bwt-runs.pl
# ABSTRACT: BWT Run Length

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

# Default options
my $input_file = 'E-coli.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my $text = path($input_file)->slurp;
chomp $text;
$text .= q{$};

printf "%s\n", join ', ', count_runs( make_bwt($text) );

# Make BWT
sub make_bwt {
    my ($text) = @_;    ## no critic (ProhibitReusedNames)

    my $text_length = length $text;

    my @positions = sort {    ## no critic (RequireSimpleSortBlock)
        my $chr_a;
        my $chr_b;
        my $i = 0;
        while ( $i < length $text ) {
            $chr_a = substr $text, ( $text_length - $a + $i ) % $text_length, 1;
            $chr_b = substr $text, ( $text_length - $b + $i ) % $text_length, 1;
            last if $chr_a ne $chr_b;
            $i++;
        }
        return $chr_a cmp $chr_b;
    } ( 0 .. $text_length - 1 );

    my $bwt = q{};
    foreach my $position (@positions) {
        $bwt .= substr $text, $text_length - 1 - $position, 1;
    }

    return $bwt;
}

# Count runs of length at least 10
sub count_runs {
    my ($bwt) = @_;

    my $count = 0;

    my $run_length = 0;
    my $last_chr   = q{};
    foreach my $chr ( split //xms, $bwt ) {
        if ( $chr ne $last_chr ) {
            $run_length = 1;
        }
        else {
            $run_length++;
        }
        if ( $run_length == 10 ) {    ## no critic (ProhibitMagicNumbers)
            $count++;
        }
        $last_chr = $chr;
    }

    return $count;
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

bwt-runs.pl

BWT Run Length

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script counts the number of runs of length 10 after Burrows-Wheeler
Transform.

Input: A string I<Text>.

Output: The number of runs of length at least 10.

=head1 EXAMPLES

    perl bwt-runs.pl

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
