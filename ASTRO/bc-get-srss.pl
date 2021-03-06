#!/bin/perl

# Obtains sunrise/sunset info from
# http://aa.usno.navy.mil/data/docs/RS_OneYear.php and puts it into an
# SQLite3 db

require "/usr/local/lib/bclib.pl";

# In theory, the POST form,
# http://aa.usno.navy.mil/cgi-bin/aa_rstablew.pl, accepts only POST
# data, but it actually accepts GET data as well

# TODO: move this declaration much further inside
my(%data);
for $i (2013..2023) {
  for $j (0..9) {
    # $i = year, $j = type of data
    my($out,$err,$res) = cache_command2("curl 'http://aa.usno.navy.mil/cgi-bin/aa_rstablew.pl?FFX=1&xxy=$i&type=$j&st=NM&place=albuquerque&ZZZ=END'","age=86400");

    # parse result
    for $k (split(/\n/, $out)) {
      # TODO: need header lines to determine what data I have, but skip for now
      # determine day (if not one, skip)
      unless ($k=~/^\s*(\d+)\s*/) {next;}
      my($day) = $1;
      # data is positional and has blanks, so can't use split() here
      for ($l=1; $l<13; $l++) {
	my($start) = substr($k,$l*11-7,4);
	my($end) = substr($k,$l*11-2,4);
	$data{$l}{$day}{start} = $start;
	$data{$l}{$day}{end} = $end;
      }
    }
    debug(%{$data{5}{11}});
  }
}


