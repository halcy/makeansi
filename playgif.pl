#!/bin/perl

use utf8;
binmode(STDOUT, ":utf8");

use warnings;
use strict;

use Image::Magick;

# Remove all formatting
sub resetformat() {
    return "\e[0m";
}

# Set fore- and background using RGB colour terminal escapes
sub rgbcol($$$) {
    my ($r, $g, $b) = @_;
    my $setfg = "\e[38;2;" . $r . ";" . $g .";" . $b . "m";
    my $setbg = "\e[48;2;" . $r . ";" . $g .";" . $b . "m";
    return resetformat() . $setfg . $setbg;
}

# Set fore- and background differently, using RGB colour terminal escapes
sub rgbcol2($$$$$$) {
    my ($rf, $gf, $bf, $rb, $gb, $bb) = @_;
    my $setfg = "\e[38;2;" . $rf . ";" . $gf .";" . $bf . "m";
    my $setbg = "\e[48;2;" . $rb . ";" . $gb .";" . $bb . "m";
    return resetformat() . $setfg . $setbg;
}

# Turn underlining on
sub underline() {
    return("\e[4m")
}

# Print a block with given colour
sub printblock($$$) {
    my ($r, $g, $b) = @_; 
    print rgbcol(int($r), int($g), int($b)) . "█" . resetformat();
}

# Print two half-blocks with given colours
sub printhalfblock($$$$$$) {
    my ($ur, $ug, $ub, $lr, $lg, $lb) = @_; 
    print rgbcol2(int($lr), int($lg), int($lb), int($ur), int($ug), int($ub));
    print underline();
    print "▄";
    print resetformat();
}

# Skip a block. Aka, print a space.
sub skipblock() {
    print " ";
}

# Go to next line
sub nextline() {
    print "\n";
}

# Emergency bailout cursor shower
$SIG{'INT'} = sub {print "\e[?25h"; exit(0);};

# Read an image
my $filename = $ARGV[0] or die("Missing file name parameter");
my $maxiters = defined($ARGV[1]) ? $ARGV[1] : 0;
my $scale = defined($ARGV[2]) ? $ARGV[2] : 1.0;
my $filter = defined($ARGV[3]) ? $ARGV[3] : "Bessel";

my $image = Image::Magick->new();
$image->read($filename);

my $width = $image->Get('width') or die("Could not read image");
my $height = $image->Get('height');

if($scale != 1.0) {
    $width = int($width * $scale);
    $height = int($height * $scale);
    $image->Resize('width' => $width, 'height' => $height, 'filter' => $filter);
}

# Cursor off, if possible
print "\e[?25l";

# Play
my $iters = 0;
while($iters < $maxiters || $maxiters == 0) {
    for(my $i = 0; $image->[$i]; $i++) {
        my $linecount = 0;
        for(my $y = 0; $y < $height; $y+=2) {
            for(my $x = 0; $x < $width; $x++) {
                my @pixels_upper = $image->[$i]->GetPixels(
                    'width'     => 1,
                    'height'    => 1,
                    'x'         => $x,
                    'y'         => $y,
                    'map'       =>'RGBA',
                );
            
                my @pixels_lower = $image->[$i]->GetPixels(
                    'width'     => 1,
                    'height'    => 1,
                    'x'         => $x,
                    'y'         => $y + 1,
                    'map'       =>'RGBA',
                );
            
                my $alpha_upper = ($pixels_upper[3] / 256.0) / 256.0;
                $pixels_upper[0] *= $alpha_upper;
                $pixels_upper[1] *= $alpha_upper;
                $pixels_upper[2] *= $alpha_upper;
            
                my $alpha_lower = ($pixels_lower[3] / 256.0) / 256.0;
                $pixels_lower[0] *= $alpha_lower;
                $pixels_lower[1] *= $alpha_lower;
                $pixels_lower[2] *= $alpha_lower;
                
                printhalfblock(
                    $pixels_upper[0] / 256, 
                    $pixels_upper[1] / 256, 
                    $pixels_upper[2] / 256,
                    $pixels_lower[0] / 256, 
                    $pixels_lower[1] / 256, 
                    $pixels_lower[2] / 256
                );
            }
            nextline();
            $linecount++;
        }
        print "\e[" . $linecount . "A";
    }
    $iters++;
}

# Cursor back on
print "\e[?25h";

