#!/bin/perl

use utf8;
use warnings;
use strict;

use Image::Magick;

# Remove all formatting
sub resetformat { "\e[0m" }

# Set fore- and background using RGB colour terminal escapes
sub rgbcol {
    my ( $r, $g, $b ) = @_;
    my $setfg = "\e[38;2;$r;$g;${b}m";
    my $setbg = "\e[48;2;$r;$g;${b}m";
    return resetformat . $setfg . $setbg;
}

# Set fore- and background differently, using RGB colour terminal escapes
sub rgbcol2 {
    my ( $rf, $gf, $bf, $rb, $gb, $bb ) = @_;
    my $setfg = "\e[38;2;$rf;$gf;${bf}m";
    my $setbg = "\e[48;2;$rb;$gb;${bb}m";
    return resetformat . $setfg . $setbg;
}

# Turn underlining on
sub underline { "\e[4m" }

# Print a block with given colour
sub printblock {
    my ( $r, $g, $b ) = @_;
    print rgbcol( map { int $_ } $r, $g, $b ) . "█" . resetformat;
    return;
}

# Print two half-blocks with given colours
sub printhalfblock {
    my ( $ur, $ug, $ub, $lr, $lg, $lb ) = @_;
    print rgbcol2( map { int $_ } $lr, $lg, $lb, $ur, $ug, $ub ) . underline . "▄" . resetformat;
    return;
}

# Skip a block. Aka, print a space.
sub skipblock { " " }

# Go to next line
sub nextline { "\n" }

binmode STDOUT, ":utf8";

# Read an image
my $filename   = $ARGV[0] or die "Missing file name parameter";
my $halfblocks = 1;
my $scale      = defined( $ARGV[1] ) ? $ARGV[1] : 1.0;
my $filter     = defined( $ARGV[2] ) ? $ARGV[2] : "Bessel";

my $image = Image::Magick->new;
$image->read( $filename );

my $width = $image->Get( 'width' ) or die "Could not read image";
my $height = $image->Get( 'height' );

if ( $scale != 1.0 ) {
    $width  = int( $width * $scale );
    $height = int( $height * $scale );
    $image->Resize( 'width' => $width, 'height' => $height, 'filter' => $filter );
}

if ( !$halfblocks ) {
    for my $y ( 0 .. $height - 1 ) {
        for my $x ( 0 .. $width - 1 ) {
            my @pixels = $image->GetPixels(
                'width'  => 1,
                'height' => 1,
                'x'      => $x,
                'y'      => $y,
                'map'    => 'RGBA',
            );
            if ( $pixels[3] > 0 ) {
                printblock map { $_ / 256 } $pixels[0], $pixels[1], $pixels[2];
            }
            else {
                skipblock;
            }
        }
        nextline;
    }
}
else {
    for ( my $y = 0 ; $y < $height ; $y += 2 ) {
        for my $x ( 0 .. $width - 1 ) {
            my @pixels_upper = $image->GetPixels(
                'width'  => 1,
                'height' => 1,
                'x'      => $x,
                'y'      => $y,
                'map'    => 'RGBA',
            );

            my @pixels_lower = $image->GetPixels(
                'width'  => 1,
                'height' => 1,
                'x'      => $x,
                'y'      => $y + 1,
                'map'    => 'RGBA',
            );

            my $alpha_upper = ( $pixels_upper[3] / 256.0 ) / 256.0;
            $pixels_upper[0] *= $alpha_upper;
            $pixels_upper[1] *= $alpha_upper;
            $pixels_upper[2] *= $alpha_upper;

            my $alpha_lower = ( $pixels_lower[3] / 256.0 ) / 256.0;
            $pixels_lower[0] *= $alpha_lower;
            $pixels_lower[1] *= $alpha_lower;
            $pixels_lower[2] *= $alpha_lower;

            printhalfblock map { $_ / 256 }    #
              $pixels_upper[0], $pixels_upper[1], $pixels_upper[2],
              $pixels_lower[0], $pixels_lower[1], $pixels_lower[2];
        }
        nextline;
    }
}
