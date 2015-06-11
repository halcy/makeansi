makeansi.pl
===========

Converts images to a sequence of ansi rgb colour code 
escapes combined with unicode half block characters,
or alternately plays back a gif file in the terminal.

For a list of terminals that actually support the 
true color ansi escape sequences, refer to 
[this list](https://gist.github.com/XVilka/8346728).

Usage:

   > perl makeansi.pl some.png

   > perl makeansi.pl some.gif 

Results should look like so:

![Ansi Marisa](http://aka-san.halcy.de/ansimari.png)

You can put the results in a text file and then just
cat it into the terminal for viewing, if you like. Yes,
even the animations. If you do that with an animation,
the frame delay is ignored, obviously.

Parameters:

   * -scale (float): Scale image to this fraction of 
      its size. Default: 1.0.
 
   * -scalefilter (string): Scale image with this 
      filter. For a list of filters, see imagemagick 
      documentation. Default: Bessel.

   * -scalegamma (float): Apply gamma correction with 
      this value while scaling. Default: 2.2.

   * -rmult (float), -gmult (float), -bmult (float): 
      Scale r, g, b components by this fraction before 
      display. Default: 1.0.
   
   * -gamma (float): Apply gamma correction with this 
      value before display. Default: 1.0 (no-op).
                 
   * -loop (int): For animations, loop this many times.
      Default: 0 (loop forever).

   * -nodelay: Turns off animation delay, frames are
      just written as fast as possible. Default: Off.

   * -frame (int): For animations, don't loop or 
      animate but instead just display frame n. 
      Default: Off.

   * -manualcoalesce - Do not rely on imagemagick 
      to coalesce the gif animation correctly, manually
      overlay images according to alpha information.
      This should hardly ever be neccesary. Default:
      Off.

Recommended console font: Droid Sans Mono

If you are a developer of a terminal emulator: Please
do implement these RGB colour code sequences, they're
really rad.


