#!/usr/bin/env perl

# PODNAME: lloyd.pl
# ABSTRACT: Lloyd algorithm for k-means clustering

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-08

use warnings;
use strict;
use autodie;
use Getopt::Long;
use Pod::Usage;
use Carp;
use Path::Tiny;
use version; our $VERSION = qv('v0.1.0');

use Storable qw(dclone);
use List::Util qw(sum);

# Default options
my $input_file = 'lloyd-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $integers, @data ) = path($input_file)->lines( { chomp => 1 } );
my ( $k, $m ) = split /\s+/xms, $integers;
@data = map { [ split /\s+/xms, $_ ] } @data;

my $centres = dclone( [ @data[ 0 .. $k - 1 ] ] );

$centres = lloyd( \@data, $centres, $k );

foreach my $centre ( @{$centres} ) {
    printf "%s\n", join q{ }, map { sprintf '%.3f', $_ } @{$centre};
}

sub lloyd {
    my ( $data, $centres, $k ) = @_;    ## no critic (ProhibitReusedNames)

    while (1) {
        my @clusters;
        foreach my $point ( @{$data} ) {
            my $nearest = nearest_centre( $point, $centres );
            push @{ $clusters[$nearest] }, $point;
        }
        my $new_centres = centres_of_gravity( \@clusters );
        my $converged = same_centres( $centres, $new_centres );
        $centres = $new_centres;
        last if $converged;
    }

    return $centres;
}

sub nearest_centre {
    my ( $point, $centres ) = @_;    ## no critic (ProhibitReusedNames)

    my $min_distance;
    my $nearest_centre;
    my $i = 0;
    foreach my $centre ( @{$centres} ) {
        my $distance = euclidean_distance( $centre, $point );
        if ( !defined $min_distance || $distance < $min_distance ) {
            $min_distance   = $distance;
            $nearest_centre = $i;
        }
        $i++;
    }

    return $nearest_centre;
}

sub euclidean_distance {
    my ( $point1, $point2 ) = @_;

    my $sum = 0;
    foreach my $i ( 0 .. scalar @{$point1} - 1 ) {
        $sum += ( $point1->[$i] - $point2->[$i] )**2;
    }

    return sqrt $sum;
}

sub centres_of_gravity {
    my ($clusters) = @_;

    my @centres;

    foreach my $cluster ( @{$clusters} ) {
        my $centre = [];
        foreach my $dimension ( 0 .. scalar @{ $cluster->[0] } - 1 ) {

            # Get average of points for this dimension
            push @{$centre},
              sum( map { $_->[$dimension] } @{$cluster} ) / scalar @{$cluster};
        }
        push @centres, $centre;
    }

    return \@centres;
}

sub same_centres {
    my ( $centres1, $centres2 ) = @_;

    foreach my $i ( 0 .. scalar @{$centres1} - 1 ) {
        foreach my $j ( 0 .. scalar @{ $centres1->[0] } - 1 ) {
            if ( $centres1->[$i][$j] != $centres2->[$i][$j] ) {
                return 0;
            }
        }
    }

    return 1;
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

lloyd.pl

Lloyd algorithm for k-means clustering

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements the Lloyd algorithm for I<k>-means clustering.

Input: Integers I<k> and I<m> followed by a set of points I<Data> in
I<m>-dimensional space.

Output: A set I<Centers> consisting of I<k> points (centers) resulting from
applying the Lloyd algorithm to I<Data> and I<Centers>, where the first I<k>
points from Data are selected as the first I<k> centers.

=head1 EXAMPLES

    perl lloyd.pl

    perl lloyd.pl \
        --input_file lloyd-extra-input.txt

    diff <(perl lloyd.pl | sort) <(sort lloyd-sample-output.txt)

    diff \
        <(perl lloyd.pl --input_file lloyd-extra-input.txt | sort) \
        <(sort lloyd-extra-output.txt)

    perl lloyd.pl --input_file dataset_10928_3.txt \
        > dataset_10928_3_output.txt

=head1 USAGE

    lloyd.pl
        [--input_file FILE]
        [--debug]
        [--help]
        [--man]

=head1 OPTIONS

=over 8

=item B<--input_file FILE>

The input file containing "Integers I<k> and I<m> followed by a set of points
I<Data> in I<m>-dimensional space".

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
