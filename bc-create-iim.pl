#!/bin/perl

# Another program that benefits only me <h>(my goal is to create one
# that benefits no body, and then maybe one that harms people
# including myself)</h>, creates an IIM iMacros file to download my
# allybank.com information

# --norun: create the macro, but don't run it in Firefox

# The macro is mostly fixed, only the dates change

require "/usr/local/lib/bclib.pl";
require "/home/barrycarter/bc-private.pl";

# the macro is mostly fixed (I could even read it from current version?)

# the "accountSelect... e*" is some hex representation of my account
# (hardcoding the first nybble is hopefully safe); do a 'view source'
# and change 'e*' if needed)

$macro = << "MARK";
TAB OPEN
TAB T=2
URL GOTO=https://secure.ally.com/allyWebClient/login.do
' TAG POS=1 TYPE=SPAN ATTR=TXT:log<SP>in
TAG POS=1 TYPE=INPUT:TEXT FORM=NAME:actionForm ATTR=ID:userNamePvtEncrypt CONTENT=$ally{username}
TAG POS=1 TYPE=INPUT:BUTTON FORM=ID:noautocomplete ATTR=NAME:continue&&VALUE:Continue
' SET !ENCRYPTION NO
TAG POS=1 TYPE=INPUT:PASSWORD FORM=NAME:actionForm ATTR=NAME:passwordPvtBlock CONTENT=$ally{password}
TAG POS=1 TYPE=INPUT:SUBMIT FORM=ID:noautocomplete ATTR=NAME:button&&VALUE:log<SP>in
URL GOTO=https://secure.ally.com/allyWebClient/downloadAccountActivity.do
TAG POS=1 TYPE=SELECT ATTR=ID:accountSelect CONTENT=%e*
TAG POS=1 TYPE=INPUT:TEXT FORM=NAME:downloadActivityForm ATTR=ID:date1 CONTENT=:STARTDATE:
TAG POS=1 TYPE=INPUT:TEXT FORM=NAME:downloadActivityForm ATTR=ID:date2 CONTENT=:ENDDATE:
TAG POS=1 TYPE=SELECT ATTR=ID:formatSelect CONTENT=%Money
TAG POS=1 TYPE=INPUT:SUBMIT FORM=NAME:downloadActivityForm ATTR=ID:mainSubmit
MARK
;

# now and 17.5 months ago (18 is limit, but playing it safe)
$now = time();
$enddate = strftime("%m/%d/%Y", localtime($now));
$startdate = strftime("%m/%d/%Y", localtime($now-365.2425/12*17.5*86400));

# substiute into macro (TODO: redundant code, use hash?, create generalized subroutine?)
$macro=~s/:STARTDATE:/$startdate/isg;
$macro=~s/:ENDDATE:/$enddate/isg;

write_file($macro, "/home/barrycarter/iMacros/Macros/bc-create-ally.iim");

# if not running macro, stop here
if ($globopts{norun}) {exit 0;}

# run the macro
# TODO: yes, this is a terrible place to keep my firefox
($out, $err, $res) = cache_command("/root/build/firefox/firefox -remote 'openURL(http://run.imacros.net/?m=bc-create-ally.iim,new-tab)'");

# not sure how long it takes to run above command, so wait until
# trans*.ofx shows up in download directory (and is fairly recent)

# TODO: this is hideous (-mmin -60 should be calculated not a guess)

for (;;) {
  ($out, $err, $res) = cache_command("find '/home/barrycarter/Download/' -iname 'trans*.ofx' -mmin -60");
  if ($out) {last;}
  debug("OUT: $out");
  sleep(1);
}

# send file to ofx parser
($out, $err, $res) = cache_command("/home/barrycarter/BCGIT/bc-parse-ofx.pl $out");

# useless fact: allybank.com names their OFX dumps as trans[x], where
# x is the unix time to the millisecond (I think)
