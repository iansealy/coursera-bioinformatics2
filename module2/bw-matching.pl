#!/usr/bin/env perl

# PODNAME: bw-matching.pl
# ABSTRACT: Burrows-Wheeler Matching

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

use sort 'stable';

# Default options
my $input_file = 'bw-matching-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $bwt, $patterns ) = path($input_file)->lines( { chomp => 1 } );

my ( $last_col, $last_to_first ) = index_bwt($bwt);

my @matches;
foreach my $pattern ( split /\s+/xms, $patterns ) {
    push @matches, count_matches( $last_col, $last_to_first, $pattern );
}

printf "%s\n", join q{ }, @matches;

# Index BWT
sub index_bwt {
    my ($bwt) = @_;    ## no critic (ProhibitReusedNames)

    my @bwt = split //xms, $bwt;

    # Create index to convert from BWT to sorted BWT
    my @index;
    my $i = 0;
    foreach
      my $j ( sort { $bwt[$a] cmp $bwt[$b] } ( 0 .. ( scalar @bwt ) - 1 ) )
    {
        $index[$j] = $i;
        $i++;
    }

    return \@bwt, \@index;
}

# Count number of matches of a pattern in BWT
sub count_matches {
    ## no critic (ProhibitReusedNames)
    my ( $last_col, $last_to_first, $pattern ) = @_;
    ## use critic

    my $top    = 0;
    my $bottom = ( scalar @{$last_col} ) - 1;

    while ( $top <= $bottom ) {
        if ($pattern) {
            ## no critic (ProhibitMagicNumbers)
            my $symbol = substr $pattern, -1, 1, q{};
            ## use critic
            my $got_symbol = 0;
            foreach my $pos ( $top .. $bottom ) {
                if ( $last_col->[$pos] eq $symbol ) {
                    $top        = $pos;
                    $got_symbol = 1;
                    last;
                }
            }
            return 0 if !$got_symbol;    # Pattern not found
            foreach my $pos ( reverse $top .. $bottom ) {
                if ( $last_col->[$pos] eq $symbol ) {
                    $bottom = $pos;
                    last;
                }
            }
            $top    = $last_to_first->[$top];
            $bottom = $last_to_first->[$bottom];
        }
        else {
            return $bottom - $top + 1;
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

bw-matching.pl

Burrows-Wheeler Matching

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements Burrows-Wheeler Matching.

Input: A string I<BWT(Text)>, followed by a collection of I<Patterns>.

Output: A list of integers, where the I<i>-th integer corresponds to the number
of substring matches of the I<i>-th member of I<Patterns> in I<Text>.

=head1 EXAMPLES

    perl bw-matching.pl

    perl bw-matching.pl --input_file bw-matching-extra-input.txt

    diff <(perl bw-matching.pl) bw-matching-sample-output.txt

    diff <(perl bw-matching.pl \
        --input_file bw-matching-extra-input.txt) bw-matching-extra-output.txt

    perl bw-matching.pl --input_file dataset_300_8.txt \
        > dataset_300_8_output.txt

=head1 USAGE

    bw-matching.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A string I<BWT(Text)>, followed by a collection of
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
