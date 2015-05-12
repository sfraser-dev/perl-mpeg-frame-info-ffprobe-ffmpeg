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
my $fh_vidLog;
my @content_vid;

# write a log of all the MPEG files found
$vidLog = "zvid.log";
open ($fh_vidLog, ">", $vidLog) || die "Couldn't open '".$vidLog."'for writing because: ".$!;

# make sure the log for ffprobe doesn't exist (as we append to it)
$probeLog = "zprobe.log";
if (-e $probeLog) {
    say "deleting probe log";
    system("del /Q $probeLog");
}

# find files with .mpg in them recursively from this directory
my $filecount=0;
find( \&wantedFilesMPG, '.');
say $fh_vidLog "Filenames with .mpg extensions";
foreach my $theFile (@content_vid) {
	$filecount ++;
    $fullFileName = abs_path($theFile);
    say "$filecount: $fullFileName";
    #say $fh_vidLog "$filecount: $theFile";
    system("echo. >>$probeLog");
    system("echo.$filecount. MPEGFileFound >>$probeLog");
    #system("echo.$fullFileName >>$probeLog");
    #system("ffprobe -show_format $fullFileName >> $probeLog 2>&1");
    system("ffprobe -show_frames -pretty $fullFileName >> $probeLog 2>&1");
    system("echo.FFMPEG to null error log >>$probeLog");
    system("ffmpeg -v error -i $fullFileName -f null - >> $probeLog 2>&1");
}
close $fh_vidLog;
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
            push @content_vid, $File::Find::name;
        }
    }
    return;
}

