#!/bin/perl

use utf8;
use warnings;
use strict;

use Image::Magick;
use Getopt::Long;

# Remove all formatting
sub resetformat { "\e[0m" }

# Set fore- and background differently, using RGB colour terminal escapes
sub rgbcol2 {
    my ( $rf, $gf, $bf, $rb, $gb, $bb ) = @_;
    my $setfg = "\e[38;2;$rf;$gf;${bf}m";
    my $setbg = "\e[48;2;$rb;$gb;${bb}m";
    return resetformat . $setfg . $setbg;
}

# Turn underlining on
sub underline { "\e[4m" }

# Print two half-blocks with given colours
sub printhalfblock {
    my ( $ur, $ug, $ub, $lr, $lg, $lb ) = @_;
    print rgbcol2( map { int $_ } $lr, $lg, $lb, $ur, $ug, $ub ) . "▄";
    return;
}

# Go to next line
sub nextline { 
    resetformat . "\n" . underline 
}

binmode STDOUT, ":utf8";

# Emergency bailout reset everything
$SIG{'INT'} = sub {
    print resetformat . "\e[?25h";
    exit 0;
};

# Parse options
my $maxiters = 0;
my $manual_coalesce = 0;
my $scale =  1.0;
my $gamma = 1.0;
my $rmult = 1.0;
my $gmult = 1.0;
my $bmult = 1.0;
my $scalegamma = 2.2;
my $scalefilter = "Bessel";

GetOptions(
    "maxiters=i" => \$maxiters,
    "manualcoalesce" => \$manual_coalesce,
    "scale=f" => \$scale,
    "gamma=f" => \$gamma,
    "rmult=f" => \$rmult,
    "gmult=f" => \$gmult,
    "bmult=f" => \$bmult,
    "scalegamma=f" => \$scalegamma,
    "scalefilter=s" => \$scalefilter,
);

# Read an image
my $filename = $ARGV[0];
my $image = Image::Magick->new();
$image->read($filename);
$image = $image->Coalesce() or die("Could not coalesce frames");

my $width = $image->Get('width') or die("Could not read image");
my $height = $image->Get('height');

if($scale != 1.0) {
    $width = int($width * $scale);
    $height = int($height * $scale);
    $image->Gamma(1.0 / $scalegamma);
    $image->Resize('width' => $width, 'height' => $height, 'filter' => $scalefilter);
    $image->Gamma($scalegamma);
}

# Cursor off, if possible
print "\e[?25l";

# Play
print underline();

my $iters       = 0;
my @last_pixels = [];
my @pixels      = ();
while ( $iters < $maxiters || $maxiters == 0 ) {
    for ( my $i = 0 ; $image->[$i] ; $i++ ) {
        @last_pixels = @pixels;
        @pixels      = ();

        my $linecount = 0;
        for ( my $y = 0 ; $y < $height ; $y += 2 ) {
            for my $x ( 0 .. $width - 1 ) {
                my @pixels_upper = $image->[$i]->GetPixels(
                    'width'  => 1,
                    'height' => 1,
                    'x'      => $x,
                    'y'      => $y,
                    'map'    => 'RGBA',
                );

                my @pixels_lower = $image->[$i]->GetPixels(
                    'width'  => 1,
                    'height' => 1,
                    'x'      => $x,
                    'y'      => $y + 1,
                    'map'    => 'RGBA',
                );

                my @last_upper = ( 0, 0, 0, 0 );
                my @last_lower = ( 0, 0, 0, 0 );
                if ( $i != 0 ) {
                    @last_upper = @{ shift @last_pixels };
                    @last_lower = @{ shift @last_pixels };
                }

                my $alpha_upper = ( $pixels_upper[3] / 256.0 ) / 256.0;
                $pixels_upper[0] *= $alpha_upper;
                $pixels_upper[0] += $last_upper[0] * ( 1.0 - $alpha_upper ) * $manual_coalesce;

                $pixels_upper[1] *= $alpha_upper;
                $pixels_upper[1] += $last_upper[1] * ( 1.0 - $alpha_upper ) * $manual_coalesce;

                $pixels_upper[2] *= $alpha_upper;
                $pixels_upper[2] += $last_upper[2] * ( 1.0 - $alpha_upper ) * $manual_coalesce;

                my $alpha_lower = ( $pixels_lower[3] / 256.0 ) / 256.0;
                $pixels_lower[0] *= $alpha_lower;
                $pixels_lower[0] += ( $last_lower[0] * ( 1.0 - $alpha_lower ) ) * $manual_coalesce;

                $pixels_lower[1] *= $alpha_lower;
                $pixels_lower[1] += ( $last_lower[1] * ( 1.0 - $alpha_lower ) ) * $manual_coalesce;

                $pixels_lower[2] *= $alpha_lower;
                $pixels_lower[2] += ( $last_lower[2] * ( 1.0 - $alpha_lower ) ) * $manual_coalesce;

                $pixels_lower[2] *= $alpha_lower; 
                $pixels_lower[2] += ($last_lower[2] * (1.0 - $alpha_lower)) * $manual_coalesce;
                
                $pixels_upper[0] *= $rmult;
                $pixels_upper[1] *= $gmult;
                $pixels_upper[2] *= $bmult;
                
                $pixels_lower[0] *= $rmult;
                $pixels_lower[1] *= $gmult;
                $pixels_lower[2] *= $bmult;

                $pixels_upper[0] = $pixels_upper[0] ** $gamma;
                $pixels_upper[1] = $pixels_upper[1] ** $gamma;
                $pixels_upper[2] = $pixels_upper[2] ** $gamma; 

                $pixels_lower[0] = $pixels_lower[0] ** $gamma;
                $pixels_lower[1] = $pixels_lower[1] ** $gamma;
                $pixels_lower[2] = $pixels_lower[2] ** $gamma;
		
                push @pixels, \@pixels_upper;
                push @pixels, \@pixels_lower;

                printhalfblock map { $_ / 256 }
                  $pixels_upper[0], $pixels_upper[1], $pixels_upper[2],
                  $pixels_lower[0], $pixels_lower[1], $pixels_lower[2];
            }
            print nextline;
            $linecount++;
        }
        print "\e[${linecount}A" if defined $image->[ $i + 1 ] or ( $iters + 1 ) != $maxiters;
    }
    $iters++;
}

print resetformat;

# Cursor back on
print "\e[?25h";

