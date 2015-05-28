#!/usr/bin/perl -w

use strict;
use File::Find;
use Digest::MD5;

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
    print "$size: @{$md5{$hash}}\n";
    $wasted += $size * (@{$md5{$hash}} - 1);
  }
}

1 while $wasted =~ s/^([-+]?\d+)(\d{3})/$1,$2/;
print "$wasted bytes in duplicated files\n";

sub check_file {
  -f && push @{$files{(stat(_))[7]}}, $File::Find::name;
}
