#!/bin/perl

# print updated text as my background image
# came from a hideously much longer program
# probably only useful to me <h>but I like spamming github</h>

require "/home/barrycarter/BCGIT/bclib.pl";

# lock
unless (mylock("bc-bg.pl","murder")) {die("Locked");}

# need current time
$now=time();
chdir(tmpdir());

# shade of blue I want to use
$blue = "128,128,255";

# no X server? die instantly (really only useful for massive rebooting
# and errors early May 2007)
if (system("xset q 1> /dev/null 2> /dev/null")) {exit(0);}

# HACK: leave n top lines blank for apps that "nest" there
# push(@info,"","","");
# last line indicates break between blank and data
push(@err,"","");
push(@info,"______________________");

# uptime (just the seconds)
$uptime = read_file("/proc/uptime");
$uptime=~s/ .*$//;
$uptime = convert_time($uptime, "%dd%Hh%Mm");

# TODO: add locking so program doesn't run twice
# TODO: add alarms (maybe)

# "daytime" stuff now replaced by bc-get-astro.pl

push(@info, "UPTIME: $uptime");

# @info = stuff we print (to top left corner)
# local and GMT time
# push(@info,strftime("MT: %Y%m%d.%H%M%S",localtime($now)));
# push(@info,strftime("GMT: %Y%m%d.%H%M%S",gmtime($now)));

# figure out what alerts to suppress
# format of suppress.txt:
# xyz stardate [suppress alert xyz until stardate (local time)]

@suppress = `egrep -v '^#' /home/barrycarter/ERR/suppress.txt`;

# know which alerts to suppress
for $i (@suppress) {
  ($key,$val) = split(/\s+/,$i);
  # if date has already occurred, ignore line
  if ($val < stardate($now,"localtime=1")) {next;}
  debug("KV: $key/$val");
  $suppress{$key}=$val;
}

debug("SUPPRESS",%suppress);

# all errors are in ERR subdir (and info alerts are there too)
for $i (glob("/home/barrycarter/ERR/*.err")) {
  for $j (split("\n",read_file($i))) {
    # unless suppressed, push to @err
    if ($suppress{$j}) {next;}
    push(@err,$j);
  }
}

# informational messages (redundant code, sigh!)
for $i (glob("/home/barrycarter/ERR/*.inf")) {
  for $j (split("\n",read_file($i))) {
    # unless suppressed, push to @info
    if ($suppress{$j}) {next;}
    push(@info,$j);
  }
}

# local weather (below info, above TZ = not great)
($out, $err, $res) = cache_command("curl -s 'http://api.wunderground.com/weatherstation/WXCurrentObXML.asp?ID=KNMALBUQ80'", "age=120");

# create hash + strip trailing .0
while ($out=~s%<(.*?)>([^<>]*?)</\1>%%is) {
  ($key, $val) = ($1, $2);
  $val=~s/\.0$//;
  $hash{$key}=$val;
}

$hash{observation_time}=~s/^last updated on //isg;


push(@info, "Local/$hash{temp_f}F/$hash{wind_dir}$hash{wind_mph}G$hash{wind_gust_mph}/$hash{relative_humidity}% ($hash{dewpoint_f}F) [$hash{observation_time}]");

debug("HASH",%hash);

# I have no cronjob for world time, so...

# hash of how I want to see the zones
# explicitly excluding the Kiritimati cheat
%zones = (
 "MT" => "US/Mountain",
 "CT" => "US/Central",
 "ET" => "US/Eastern",
 "PT" => "US/Pacific",
 "GMT" => "GMT",
 "Lagos" => "Africa/Lagos",
 "Cairo" => "Africa/Cairo",
 "HongKong" => "Asia/Hong_Kong",
 "Tokyo" => "Asia/Tokyo",
 "Delhi" => "Asia/Kolkata",
 "Sydney" => "Australia/Sydney",
 "Samoa" => "Pacific/Apia",
 "Pago Pago" => "Pacific/Pago_Pago",
 "Manila" => "Asia/Manila"
);

# HACK: manual sorting is cheating/dangerous ... should be able to do
# this auto somehow (eg, by deviation from GMT?)

@zones= ("Pago Pago", "PT", "MT", "CT", "ET", "GMT", "Lagos",
	 "Cairo", "Delhi",
	 "HongKong", "Manila", "Tokyo", "Sydney", "Samoa");

for $i (@zones) {
  $ENV{TZ} = $zones{$i};
  push(@info, strftime("$i: %H%M,%a%d%b",localtime(time())));
}

# random (but predictable) word from BCGIT/WWF/enable-random.txt
# 172820 is fixed
$num = ($now/60)%172820;
debug("NUM: $num");
$res = `head -$num /home/barrycarter/BCGIT/WWF/enable-random.txt | tail -1`;
chomp($res);
push(@info, "WOTM: $res");

# experimental: moon phase in middle of screen
# TODO: maybe change bgcolor based on twilight?
if (-f "/home/barrycarter/ERR/urc.gif") {
  push(@fly, "copy 472,334,0,0,100,100,/home/barrycarter/ERR/urc.gif");
}

# push output to .fly script
# err gets pushed first (and in red), then info
for $i (@err) {
  # TODO: order these better
  push(@rss, "$i");
  push(@fly, "string 255,0,0,0,$pos,giant,$i");
  $pos+=15;
}

# now info (in blue for now); note $pos is "global"
for $i (@info) {
  # TODO: order these better
  push(@rss, "$i");
  push(@fly, "string $blue,0,$pos,medium,$i");
  $pos+=15;
}

# puts the International Phonetic Alphabet at the bottom right corner
# of the screen (as I am trying to learn it); technique should be
# general enough to work with any file

open(A,"tac /home/barrycarter/BCGIT/db/ipa.txt|");
$br = 768-20; # bottom y value

while (<A>) {
  chomp;
  $br -= 15;
  # this is left justified, which means it won't work for arb files, sigh
  $xval = 950;
  push(@fly, "string $blue,$xval,$br,medium,$_");
  debug("CHOMP: $_");
}

# create RSS (not working, will probably dump)
open(A, ">/var/tmp/bc-bg.rss");
print A qq%<?xml version="1.0" encoding="ISO-8859-1" ?><rss version="0.91">
<channel><title>bc-bg</title><item><title>\n%;
print A join("&lt;br&gt;\n", @rss),"\n";
print A "</title></item></channel></rss>\n";
close(A);

# sometimes, report scrolls off screen; this sends EOF (in darker
# color) so I know where report ends
push(@fly, "string 0,0,255,0,$pos,medium,--EOF--");

# send header and output to fly file
# tried doing this w/ pipe but failed
# setpixel below needed so bg color is black
# the gray x near middle of screen is so I know a black window isn't covering root
open(A, "> bg.fly");
print A << "MARK";
new
size 1024,768
setpixel 0,0,0,0,0
setpixel 512,384,255,255,255
MARK
    ;

for $i (@fly) {print A "$i\n";}
close(A);

# also copy file since I will need it on other machines
system("fly -q -i bg.fly -o bg.gif; xv +noresetroot -root -quit bg.gif; cp bg.gif /tmp/bgimage.gif");

# call bc-get-astro.pl for next minute (calling it after generatinv
# the bg image avoids race condition); must restore timezone
$ENV{TZ} = "MST7MDT";
system("/home/barrycarter/BCGIT/ASTRO/bc-get-astro.pl");

# unlock
mylock("bc-bg.pl","unlock");

