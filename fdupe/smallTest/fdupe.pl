#!/usr/bin/perl -w
use strict;
use warnings;
use feature qw(say);
use File::Find; 
use File::Basename;
use File::Copy qw(move);
use Cwd;
use Cwd 'abs_path';
use Digest::MD5;

# ffmpeg -i video.mpg -r 25 -s cif -f image2 img%10d.png

my $log = "dupe.log";
open (my $fhLog, ">", $log) || die "Couldn't open '".$log."'for writing because: ".$!;


my %files;
my $wasted = 0;
find(\&check_file, $ARGV[0] || ".");

local $" = ", ";
foreach my $size (sort {$b <=> $a} keys %files) {
  next unless @{$files{$size}} > 1;
  my %md5;
  foreach my $file (@{$files{$size}}) {
    open(FILE, $file) or next;
    binmode(FILE);
    push @{$md5{Digest::MD5->new->addfile(*FILE)->hexdigest}},$file;
  }
  foreach my $hash (keys %md5) {
    next unless @{$md5{$hash}} > 1;
    say $fhLog "$size: @{$md5{$hash}}";
    $wasted += $size * (@{$md5{$hash}} - 1);
  }
}

1 while $wasted =~ s/^([-+]?\d+)(\d{3})/$1,$2/;

if($wasted eq 0) {
    say $fhLog "No duplicated files";
}
else {
    say $fhLog "$wasted bytes in duplicated files";
}

close($fhLog);


sub check_file {
  -f && push @{$files{(stat(_))[7]}}, $File::Find::name;
}
