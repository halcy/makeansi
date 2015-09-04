use Time::HiRes;

my $videofile = $ARGV[0];
my $columns = $ARGV[1];
my $subpos = $ARGV[2];

my $substext = `ffmpeg -vn -an -i $videofile -scodec ass -f rawvideo - 2> /dev/null`;
my @subssplit = split("\n", $substext);
my @subs = ();
for(@subssplit) {
	chomp;
	$_ =~ s/\r//;
	if($_ =~ /^Dialogue:.*,([0-9]+)[^0-9]([0-9]+)[^0-9]([0-9]+)[^0-9]([0-9]+),([0-9]+)[^0-9]([0-9]+)[^0-9]([0-9]+)[^0-9]([0-9]+),[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,[^,]*,(.*)$/) { 
		my $time = $1 * 60.0 * 60.0 + $2 * 60.0 + $3 * 1.0 + $4 / 100.0; 
		my $timeend = $5 * 60.0 * 60.0 + $6 * 60.0 + $7 * 1.0 + $8 / 100.0; 
		my $text = $9;
		push @subs, [$time, $timeend, $text];
	}
}
@subs = sort {@{$a}[0] <=> @{$b}[0]} @subs;


my $s = Time::HiRes::time();
my $subidx = 0;
my @activesubs = ();
my $maxidx = (scalar @subs) - 1;
while(1){
	my $t = Time::HiRes::time() - $s;
	if($subidx <= $maxidx) {
		while($subs[$subidx]->[0] < $t) {
			$subidx++;
			push @activesubs, $subs[$subidx];
		}
	}
	my $frame = `ffmpeg -ss $t -i $videofile -vf scale=$columns:-1 -vframes 1 -f image2 -vcodec png - 2>/dev/null | perl makeansi.pl -doreset -pipepng`;
	print "\e[0G";
	print $frame;
	
	if(scalar @activesubs > 0) {
		my $subposproper = $subpos - (scalar @activesubs);
		print "\e[" . $subposproper . "B";
		my @nextsubs = ();
		for(@activesubs) {
			my $substart = ($columns / 2) - (length($_->[2]) / 2);
			$substart = $substart < 0 ? 0 : $substart;
			$substart = int($substart);
			print "\e[" . $substart . "G";
			print $_->[2];
			print "\e[1B";
			if($_->[1] > $t) {
				push @nextsubs, $_;
			}
		}
		@activesubs = @nextsubs;
		print "\e[" . $subpos . "A";
	}
}
