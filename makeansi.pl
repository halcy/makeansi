#!/bin/perl

use utf8;
use warnings;
use strict;

use Image::Magick;
use Getopt::Long;
use Time::HiRes;

# Remove all formatting
sub resetformat { "\e[0m" }

# Set fore- and background differently, using RGB colour terminal escapes
sub rgbcol2 {
    my ($rf, $gf, $bf, $rb, $gb, $bb) = @_;
    my $setfg = "\e[38;2;$rf;$gf;${bf}m";
    my $setbg = "\e[48;2;$rb;$gb;${bb}m";
    return resetformat . $setfg . $setbg;
}

# Turn underlining on
sub underline { "\e[4m" }

# Two half-blocks with given colours (in a single character)
sub halfblock {
    my ($ur, $ug, $ub, $lr, $lg, $lb) = @_;
    return rgbcol2(map { int $_ } $lr, $lg, $lb, $ur, $ug, $ub) . "▄";
}

# Go to next line
sub nextline { 
    resetformat . "\n" . underline 
}

# Hide the terminal cursor
sub hidecursor {
    return "\e[?25l";
}

# Show the terminal cursor
sub showcursor {
    return "\e[?25h";
}

# Go n lines up
sub backnlines {
    my $line_count = shift();
    return "\e[${line_count}A";
}

# Emergency bailout. On first try, just stop animation. Second, quit right away.
my $numints = 0;
my $stop_animating = 0;
$SIG{'INT'} = sub {
    $numints++;
    if($numints == 1) {
        $stop_animating = 1;
    }
    else {
        print resetformat . showcursor;
        exit 0;
    }
};

binmode STDOUT, ":utf8";

# Parse options
my $loops = 0;
my $manual_coalesce = 0;
my $scale = 1.0;
my $gamma = 1.0;
my $rmult = 1.0;
my $gmult = 1.0;
my $bmult = 1.0;
my $scale_gamma = 2.2;
my $scale_filter = "Bessel";
my $frame = -1;
my $no_delay = 0;

GetOptions(
    "loop=i" => \$loops,
    "manualcoalesce" => \$manual_coalesce,
    "scale=f" => \$scale,
    "gamma=f" => \$gamma,
    "rmult=f" => \$rmult,
    "gmult=f" => \$gmult,
    "bmult=f" => \$bmult,
    "scalegamma=f" => \$scale_gamma,
    "scalefilter=s" => \$scale_filter,
    "frame=i" => \$frame,
    "nodelay" => \$no_delay,
);
my @colmult = ($rmult, $gmult, $bmult);

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
    $image->Gamma(1.0 / $scale_gamma);
    $image->Resize(
        'width' => $width, 
        'height' => $height, 
        'filter' => $scale_filter
    );
    $image->Gamma($scale_gamma);
}

# Single-frame images are only displayed once, no loop
if((scalar @{$image}) <= 1) {
    $frame = 0;
    $loops = 1;
}

# Convert image to ansi+unicode and get frame delays
my @last_pixels = [];
my @pixels = ();
my @ansi_frames = ();
my @line_counts = ();
my @frame_delays = ();
for(my $i = 0; $image->[$i]; $i++) {
    my $frame_ansi = "";
    
    @last_pixels = @pixels;
    @pixels = ();
    
    my $line_count = 0;
    for(my $y = 0; $y < $height; $y += 2) {
        for(my $x = 0; $x < $width; $x++) {
            my @pixels_upper = $image->[$i]->GetPixels(
                'width'  => 1,
                'height' => 1,
                'x'      => $x,
                'y'      => $y,
                'map'    => 'RGBA',
           );

            my @pixels_lower = (0, 0, 0, 0);
            if($y + 1 < $height) {
                @pixels_lower = $image->[$i]->GetPixels(
                    'width'  => 1,
                    'height' => 1,
                    'x'      => $x,
                    'y'      => $y + 1,
                    'map'    => 'RGBA',
               );
            }
            
            my @last_upper = (0, 0, 0, 0);
            my @last_lower = (0, 0, 0, 0);
            if ($i != 0) {
                @last_upper = @{ shift @last_pixels };
                @last_lower = @{ shift @last_pixels };
            }

            for(my $j = 0; $j < 3; $j++) {
                my $alpha_upper = ($pixels_upper[3] / 256.0) / 256.0;
                $pixels_upper[$j] *= $alpha_upper;
                $last_upper[$j] *= (1.0 - $alpha_upper) * $manual_coalesce;
                $pixels_upper[$j] += $last_upper[$j];
                $pixels_upper[$j] *= $colmult[$j];
                $pixels_upper[$j] = $pixels_upper[$j] ** $gamma;
                
                my $alpha_lower = ($pixels_lower[3] / 256.0) / 256.0;
                $pixels_lower[$j] *= $alpha_lower;
                $last_lower[$j] *= (1.0 - $alpha_lower) * $manual_coalesce;
                $pixels_lower[$j] += $last_lower[$j];
                $pixels_lower[$j] *= $rmult;
                $pixels_lower[$j] = $pixels_lower[$j] ** $gamma;
            }
    
            push @pixels, \@pixels_upper;
            push @pixels, \@pixels_lower;

            my @colours = map { $_ / 256 }
                $pixels_upper[0], $pixels_upper[1], $pixels_upper[2],
                $pixels_lower[0], $pixels_lower[1], $pixels_lower[2];
                
            $frame_ansi .= halfblock(@colours);
        }
        $frame_ansi .= nextline;
        $line_count++;
    }
    push @ansi_frames, $frame_ansi;
    push @line_counts, $line_count;
    push @frame_delays, (($image->[$i]->Get("delay") * 10.0) / 1000.0);
}

# Cursor off, if possible
print hidecursor;

# Play
print underline;

my $iters = 0;
my $frame_time = Time::HiRes::time();
while($iters < $loops || $loops == 0) {
    for(my $i = 0; $i < scalar @ansi_frames; $i++) {
        if($frame != -1 && $frame != $i) {
            next;
        }
        
        # Print actual frame
        print $ansi_frames[$i];
        
        # Bailout code
        if($stop_animating) {
            print resetformat . showcursor;
            exit(0);
        }
        
        # Scroll back up for next frame, if there is one
        if(($i + 1) < scalar @ansi_frames || ($iters + 1) != $loops) {
            print backnlines($line_counts[$i])
        }
        
        # Wait for frame delay to pass
        if(!$no_delay) {
            my $time = Time::HiRes::time();
            while($time - $frame_time < $frame_delays[$i]) {
                Time::HiRes::sleep((1.0 / 100.0) / 2.0);
                $time = Time::HiRes::time();
            }
            $frame_time = $time;
        }
    }
    
    $iters++;
}

print resetformat;

# Cursor back on
print showcursor;

