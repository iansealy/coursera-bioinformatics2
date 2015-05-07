#!/usr/bin/env perl

# PODNAME: farthest-first-traversal.pl
# ABSTRACT: Farthest First Traversal clustering heuristic

## Author     : Ian Sealy
## Maintainer : Ian Sealy
## Created    : 2015-05-06

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
my $input_file = 'farthest-first-traversal-sample-input.txt';
my ( $debug, $help, $man );

# Get and check command line options
get_and_check_options();

my ( $integers, @data ) = path($input_file)->lines( { chomp => 1 } );
my ( $k, $m ) = split /\s+/xms, $integers;
@data = map { [ split /\s+/xms, $_ ] } @data;

my $centres = farthest_first_traversal( \@data, $k );

foreach my $centre ( @{$centres} ) {
    printf "%s\n", join q{ }, @{$centre};
}

sub farthest_first_traversal {
    my ( $data, $k ) = @_;    ## no critic (ProhibitReusedNames)

    my @centres = ( $data->[0] );

    while ( scalar @centres < $k ) {
        my $furthest_point = furthest_point( $data, \@centres );
        push @centres, $furthest_point;
    }

    return \@centres;
}

sub furthest_point {
    my ( $data, $centres ) = @_;    ## no critic (ProhibitReusedNames)

    my $max_distance = 0;
    my $max_point;
    foreach my $point ( @{$data} ) {
        my $distance = min_distance_to_centres( $point, $centres );
        if ( $distance > $max_distance ) {
            $max_distance = $distance;
            $max_point    = $point;
        }
    }

    return $max_point;
}

sub min_distance_to_centres {
    my ( $point, $centres ) = @_;    ## no critic (ProhibitReusedNames)

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

farthest-first-traversal.pl

Farthest First Traversal clustering heuristic

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This script implements the Farthest First Traversal clustering heuristic.

Input: Integers I<k> and I<m> followed by a set of points I<Data> in
I<m>-dimensional space.

Output: A set I<Centers> consisting of I<k> points (centers) resulting from
applying B<FarthestFirstTraversal>(I<Data>, I<k>), where the first point from
I<Data> is chosen as the first center to initialize the algorithm.

=head1 EXAMPLES

    perl farthest-first-traversal.pl

    perl farthest-first-traversal.pl \
        --input_file farthest-first-traversal-extra-input.txt

    diff <(perl farthest-first-traversal.pl | sort) \
        <(sort farthest-first-traversal-sample-output.txt)

    diff \
        <(perl farthest-first-traversal.pl \
            --input_file farthest-first-traversal-extra-input.txt | sort) \
        <(sort farthest-first-traversal-extra-output.txt)

    perl farthest-first-traversal.pl --input_file dataset_10926_14.txt \
        > dataset_10926_14_output.txt

=head1 USAGE

    farthest-first-traversal.pl
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
