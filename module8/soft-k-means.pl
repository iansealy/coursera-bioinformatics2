#!/usr/bin/env perl

# PODNAME: soft-k-means.pl
# ABSTRACT: Expectation maximization algorithm for soft k-means clustering

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-12

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Readonly;
use Storable qw(dclone);
use List::Util qw(sum);

# Constants
Readonly our $STEPS => 100;    # EM steps

# Default options
my $input_file = 'soft-k-means-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $integers, $beta, @data ) = path($input_file)->lines( { chomp => 1 } );
my ( $k, $m ) = split /\s+/xms, $integers;
@data = map { [ split /\s+/xms, $_ ] } @data;

my $centres = dclone( [ @data[ 0 .. $k - 1 ] ] );

$centres = soft_k_means( \@data, $centres, $beta );

foreach my $centre ( @{$centres} ) {
    printf "%s\n", join q{ }, map { sprintf '%.3f', $_ } @{$centre};
}

sub soft_k_means {
    my ( $data, $centres, $beta ) = @_;    ## no critic (ProhibitReusedNames)

    foreach ( 1 .. $STEPS ) {

        # Expectation
        my $hidden_matrix = [];
        foreach my $point ( @{$data} ) {
            my $total_responsibility = 0;
            foreach my $i ( 0 .. scalar @{$centres} - 1 ) {
                my $dist = euclidean_distance( $centres->[$i], $point );
                my $responsibility = exp -( $beta * $dist );
                push @{ $hidden_matrix->[$i] }, $responsibility;
                $total_responsibility += $responsibility;
            }
            foreach my $i ( 0 .. scalar @{$centres} - 1 ) {
                $hidden_matrix->[$i]->[-1] /= $total_responsibility;
            }
        }

        # Maximisation
        my $new_centres = [];
        foreach my $i ( 0 .. scalar @{$centres} - 1 ) {
            my $divisor = sum( @{ $hidden_matrix->[$i] } );
            foreach my $dim ( 0 .. scalar @{ $centres->[0] } - 1 ) {
                my $dot_product = 0;
                foreach my $n ( 0 .. scalar @{$data} - 1 ) {
                    $dot_product +=
                      $data->[$n]->[$dim] * $hidden_matrix->[$i]->[$n];
                }
                push @{ $new_centres->[$i] }, $dot_product / $divisor;
            }
        }
        $centres = $new_centres;
    }

    return $centres;
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

soft-k-means.pl

Expectation maximization algorithm for soft k-means clustering

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements the expectation maximization algorithm for soft k-means
clustering.

Input: Integers I<k> and I<m>, followed by a stiffness parameter I<β>, followed
by a set of points I<Data> in I<m>-dimensional space.

Output: A set I<Centers> consisting of I<k> points (centers) resulting from
applying the expectation maximization algorithm for soft I<k>-means clustering.
Select the first I<k> points from I<Data> as the first centers for the algorithm
and run the algorithm for 100 E-steps and 100 M-steps. Results should be
accurate up to three decimal places.

=head1 EXAMPLES

    perl soft-k-means.pl

    perl soft-k-means.pl --input_file soft-k-means-extra-input.txt

    diff <(perl soft-k-means.pl | sort) <(sort soft-k-means-sample-output.txt)

    diff \
        <(perl soft-k-means.pl \
            --input_file soft-k-means-extra-input.txt | sort) \
        <(sort soft-k-means-extra-output.txt)

    perl soft-k-means.pl --input_file dataset_10933_7.txt \
        > dataset_10933_7_output.txt

=head1 USAGE

    soft-k-means.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "Integers I<k> and I<m>, followed by a stiffness
parameter I<β>, followed by a set of points I<Data> in I<m>-dimensional space".

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
