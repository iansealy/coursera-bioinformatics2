#!/usr/bin/env perl

# PODNAME: squared-error-distortion.pl
# ABSTRACT: Squared Error Distortion

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-07

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Storable qw(dclone);

# Default options
my $input_file = 'squared-error-distortion-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $integers, @data ) = path($input_file)->lines( { chomp => 1 } );
my ( $k, $m ) = split /\s+/xms, $integers;
@data = map { [ split /\s+/xms, $_ ] } @data;
my @centres;
while (1) {
    my $point = shift @data;
    last if $point->[0] eq '--------';
    push @centres, $point;
}

printf "%.3f\n", distortion( \@data, \@centres );

sub distortion {
    my ( $data, $centres ) = @_;

    my $sum_squares = 0;

    foreach my $point ( @{$data} ) {
        my $distance = min_distance_to_centres( $point, $centres );
        $sum_squares += $distance * $distance;
    }

    return $sum_squares / scalar @{$data};
}

sub min_distance_to_centres {
    my ( $point, $centres ) = @_;

    my $min;
    foreach my $centre ( @{$centres} ) {
        my $distance = euclidean_distance( $centre, $point );
        if ( !defined $min || $distance < $min ) {
            $min = $distance;
        }
    }

    return $min;
}

sub euclidean_distance {
    my ( $point1, $point2 ) = @_;

    my $sum = 0;
    foreach my $i ( 0 .. scalar @{$point1} - 1 ) {
        $sum += ( $point1->[$i] - $point2->[$i] )**2;
    }

    return sqrt $sum;
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

squared-error-distortion.pl

Squared Error Distortion

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script solves the Squared Error Distortion Problem.

Input: A set of points I<Data> and a set of centers I<Centers>. 

Output: The squared error distortion I<Distortion>(I<Data>, I<Centers>). 

=head1 EXAMPLES

    perl squared-error-distortion.pl

    perl squared-error-distortion.pl \
        --input_file squared-error-distortion-extra-input.txt

    diff <(perl squared-error-distortion.pl) \
        squared-error-distortion-sample-output.txt

    diff \
        <(perl squared-error-distortion.pl \
            --input_file squared-error-distortion-extra-input.txt) \
        squared-error-distortion-extra-output.txt

    perl squared-error-distortion.pl --input_file dataset_10927_3.txt \
        > dataset_10927_3_output.txt

=head1 USAGE

    squared-error-distortion.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "A set of points I<Data> and a set of centers
I<Centers>".

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
