makeansi.pl
===========

Converts images to a sequence of ansi rgb colour code 
escapes combined with unicode half block characters,
or alternately plays back a gif file in the terminal.

For a list of terminals that actually support the true
color ansi escape sequences, refer to this list:

   https://gist.github.com/XVilka/8346728

Usage:

   perl makeansi.pl some.png <scale factor> <filter>
   perl playgif.pl some.gif <loops> <scale> <filter>

Results should look like so:

![Ansi Marisa](http://aka-san.halcy.de/ansimari.png)

You can put the results in a text file and then just
cat it into the terminal for viewing, if you like. Yes,
even the animations. Frame delay is ignored right now.

Recommended console font: Droid Sans Mono

If you are a developer of a terminal emulator: Please
do implement these RGB colour code sequences, they're
really rad.


