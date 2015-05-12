#!/usr/bin/perl -w
use strict;
use warnings;
use feature qw(say);
use File::Find; 
use File::Basename;
use Cwd;

my $name;
my $dir;
my $ext;
my $filePath;
my $fileDataset;
my $fileSubProject;
my $filePathName;
my @content;
my $fout;
my $fh_out;
my $container;
my $probe;
my @probeArr;
my $frameRate = "";
my $mediaType = "";
my $timeCode = "";
my $pkt_pts = "";
my $pkt_pts_time = "";
my $pkt_dts = "";
my $pkt_dts_time = "";
my $pict_type = "";
my $frame_info = "";
my $media_type = "";
my $titlepart = "";
my $datapart = "";

$fout = "VideoInfo.csv";
open ($fh_out, ">", $fout) || die "Couldn't open '".$fout."'for writing because: ".$!;

# Write a file header
say $fh_out "filecount, framecount, media_type, pkt_pts, pkt_pts_time, pkt_dts, pkt_dts_time, pict_type, filepath, filename";

# find .mp4 files recursively from this directory
my $filecount=0;
find( \&mp4Wanted, '.');
foreach my $mp4Name (@content) {
	# file path and name
	($name,$dir,$ext) = fileparse($mp4Name,'\..*');
	$filePath = cwd();
	$fileSubProject = substr $dir, 2;
	$fileDataset = "$filePath/$fileSubProject";
	#$filePathName = "$filePath/.../$name$ext";
	$filePathName = "$fileDataset/.../$name$ext";
	$filecount ++;
    
	#Frame sequence?
	@probeArr = `ffprobe -show_frames -i $mp4Name`;
	my $framecount=0;
	foreach my $i (@probeArr){
		chomp $i;
		
		# divide the string into its title and data, e.g. "a=2" becomes titlepart a, and datapart 2
		# except if the entry is the start or end marker for a frame
		$datapart = "";
		if ($i =~ '\[FRAME'){
			$titlepart = "FRAME_START";
		}
		elsif ($i =~ 'FRAME'){	
			$titlepart = "FRAME_END";
		}
		else {	
			$titlepart = substr($i,0,index($i,"="));
			$datapart = substr($i,index($i,"=")+1);
		}
		
		# [FRAME] 
		if ($titlepart eq "FRAME_START"){
			$frame_info="";
		}
		# media_type 
		elsif ($titlepart eq "media_type"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		# pkt_pts 
		elsif ($titlepart eq "pkt_pts"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		# pkt_pts_time
		elsif ($titlepart =~ "pkt_pts_time"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		# pkt_dts 
		elsif ($titlepart =~ "pkt_dts"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		# pkt_dts_time
		elsif ($titlepart =~ "pkt_dts_time"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		 # pict_type
		elsif ($titlepart =~ "pict_type"){
			$frame_info = $frame_info . ', ' . $datapart;
		}
		# [/FRAME] 
		elsif ($titlepart eq "FRAME_END"){
			#end of frame: time to print but only write to file if this is a video frame not audio
			if (index($frame_info, 'video') != -1) {
				$framecount ++;
				say $fh_out "$filecount, $framecount $frame_info, $fileDataset, $name$ext";
			}
		}

	}

	# write to output file
	#say $fh_out "$pkt_pts, $pkt_pts_time, $pkt_dts, $pkt_dts_time, $pict_type";
	say "$filePathName ... done";
	
    
}
close $fh_out;
close $fout;
exit;

# subroutine to recursively find all files with ".mp4" extension
sub mp4Wanted {
    if ($File::Find::name =~ /.mp4/){
        push @content, $File::Find::name;
    }
    return;
}


