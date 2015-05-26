#!/usr/bin/perl -w
use strict;
use warnings;
use feature qw(say);
use File::Find; 
use File::Basename;
use File::Copy qw(move);
use Cwd;
use Cwd 'abs_path';

my $fullFileName;
my $vidLog;
my $probeLog;
my @foundVid;
my @probeArr;
my $dataPart;
my $titlePart;
my $frameInfo;
my $fileCount=0;
my $frameCount=0;
my $mediaType;		
my $pktPts;
my $pktPtsTime;
my $pktDts;
my $pktDtsTime;
my $pictType;
my $pktSize;
my $bestEffortTimestampTime;
my $numArgs;
my $minBytes;
my $minutes;
my $smallFramesFound=0;

$numArgs = $#ARGV + 1;
if ($numArgs != 1){
    say "Usage: Please input a minimum number of bytes for a video frame";
    exit;
}

# make sure the log for ffprobe doesn't exist (as we append to it)
$probeLog = "zprobe.log";
if (-e $probeLog) {
    say "deleting probe log";
    system("del /Q $probeLog");
}
$minBytes = $ARGV[0];

# find files with .mpg in them recursively from this directory
find( \&wantedFilesMPG, '.');
foreach my $theVidFile (@foundVid) {
	$fileCount ++;
    $fullFileName = abs_path($theVidFile);
    system("echo. >>$probeLog");
    system("echo.$fileCount. MPEGFileFound >>$probeLog");
    system("echo.$fullFileName >>$probeLog");
    
    @probeArr = `ffprobe -show_frames -i $theVidFile`;
    foreach my $i (@probeArr) {
        chomp $i;

        # divide the string into its title and data, e.g. "a=2" becomes titlePart a, and dataPart 2
		# except if the entry is the start or end marker for a frame
		$dataPart = "";
		if ($i =~ '\[FRAME'){
			$titlePart = "FRAME_START";
		}
		elsif ($i =~ 'FRAME'){	
			$titlePart = "FRAME_END";
		}
		else {	
			$titlePart = substr($i,0,index($i,"="));
			$dataPart = substr($i,index($i,"=")+1);
		}
		
        # [FRAME] 
		if ($titlePart eq "FRAME_START"){
            #
		}
		# media_type 
		elsif ($titlePart eq "media_type"){
            $mediaType = $dataPart;
		}
		# pkt_pts 
		elsif ($titlePart eq "pkt_pts"){
            $pktPts = $dataPart;
		}
		# pkt_pts_time
		elsif ($titlePart =~ "pkt_pts_time"){
            $pktPtsTime = $dataPart;
		}
		# pkt_dts 
		elsif ($titlePart =~ "pkt_dts"){
            $pktDts = $dataPart;
		}
		# pkt_dts_time
		elsif ($titlePart =~ "pkt_dts_time"){
            $pktDtsTime = $dataPart;
		}
		# pict_type
		elsif ($titlePart =~ "pict_type"){
            $pictType = $dataPart;
		}
		# pkt_size
		elsif ($titlePart =~ "pkt_size"){
            $pktSize = $dataPart;
		}
		# best_effort_timestamp_time
		elsif ($titlePart =~ "best_effort_timestamp_time"){
            $bestEffortTimestampTime = $dataPart;
		}
		# [/FRAME] 
        elsif ($titlePart eq "FRAME_END"){
			#end of frame: time to print but only write to file if this is a video frame not audio
			if (index($mediaType, 'vide') != -1) {
				$frameCount ++;
                if ($pktSize < $minBytes) {
                    $smallFramesFound++;
                    system("echo. >>$probeLog");
                    system("echo.Very small compressed frame found >>$probeLog");
                    system("echo.frameCount = $frameCount>>$probeLog");
                    system("echo.pkt_size = $pktSize>>$probeLog");
                    system("echo.bestEffortTimestampTime = $bestEffortTimestampTime>>$probeLog");
                }
			}
		}
    }
}

# Summarise findings
$minutes =  $bestEffortTimestampTime / 60;
system("echo. >>$probeLog");
system("echo.Summary >>$probeLog");
system("echo.Seconds of video = $bestEffortTimestampTime>>$probeLog");
system("echo.Minutes of video = $minutes>>$probeLog");
system("echo.Small compressed frames found = $smallFramesFound>>$probeLog");
say "\nSummary";
say "Seconds of video = $bestEffortTimestampTime ($minutes minutes)";
say "Small compressed frames found = $smallFramesFound";

exit;

# subroutine to recursively find MPG files
sub wantedFilesMPG {
    # find files containing ".mpg" anywhere in their name
    # (note some Vim swap files will also contain ".mpg" within their filenames)
    if ($File::Find::name =~ /\.mpg/){ 
        # get the filename extension by matching a dot,
        # followed by any numeber of dots, until the end of the file
        my  ($ext) = $File::Find::name =~ /(\.[^.]+)$/;
        if ($ext eq ".mpg") {
            push @foundVid, $File::Find::name;
        }
    }
    return;
}

