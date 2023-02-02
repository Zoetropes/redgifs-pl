#!/usr/bin/perl
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>

use LWP;
use URI;
use JSON;
use HTTP::Request;

$|=1;
my $ua=LWP::UserAgent->new(keep_alive=>0,timeout=>10);
$ua->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36");

sub get_token {
  my $res=$ua->get("https://api.redgifs.com/v2/auth/temporary");
  my $token=$1 if ($res->content=~/"token":"(.+?)"/);
  if (!$token) {
    print "Unable to authenticate, exiting...\n";
    exit(0);
  }
  return $token;
}

sub get_recurse {
  my $token=shift; my $who=shift; my $opt=shift; my %opt=%{$opt};
  my $pageno=int(shift); $pageno=1 unless($pageno);
  $type="g"; $type="i" if ($opt{'images'}); $type="" if ($opt{'all'});
  $token=get_token() unless ($token);
  my $uri=URI->new("https://api.redgifs.com/v2/users/$who/search?order=recent&type=$type&page=$pageno");
  my $res=$ua->get($uri,"Authorization"=>"Bearer $token","Referer"=>"https://www.redgifs.com/","X-CustomHeader"=>"https://www.redgifs.com/users/$who?type=$type&page=$pageno");
  my $page=decode_json($res->content);
  if (int($res->code)==401) {
    print "Authentication expired, please renew!\n";
    exit(0);
  }
  my %page=%$page;
  my @gifs=@{$page{'gifs'}};
  my $pages=int(@{$page}{'pages'});
  my @gifs=@{$page{'gifs'}};
  foreach $gif (@gifs) {
    my $username=%{$gif}{'userName'};
    mkdir("$username");
    my $createdate=%{$gif}{'createDate'};
    my $url=%{$gif}{'urls'}->{'hd'};
    next unless($url);
    my $fn=$1 if ($url=~/com\/(.+?\.(mp4|jpg))/);
    next unless($fn);
    next if (-f "$username/$fn"&&$opt{'skip'});
    my ($nn)=split(/\./,$fn);
    print "[$pageno/$pages][$username] $nn... " unless ($opt{'quiet'});
    my $req=HTTP::Request->new("GET",$url);
    my ($on,$cnt)=($fn,0);
    while ($opt{'noclobber'}&&-f "$username/$fn") { $cnt++; $fn=$on.".".$cnt; }
    my $res=$ua->request($req,"$username/$fn");
    utime($createdate,$createdate,"$username/$fn");
    print "OK\n" unless ($opt{'quiet'});
  }
  get_recurse($token,$who,$pageno+1,\%opt) if ($pageno<$pages);
}

my %opt;
while (my $opt=shift(@ARGV)) {
  if ($opt=~/^-/) {
    $opt{'images'}=1 if ($opt=~/i/); $opt{'all'}=1 if ($opt=~/a/); $opt{'skip'}=1 if ($opt=~/s/); $opt{'quiet'}=1 if ($opt=~/q/); $opt{'noclobber'}=1 if ($opt=~/n/);
  } else {
    $who=$opt;
  }
}
if (!$who) {
  print "Usage: $0 [-i|a|s|n] <who>\n\n";
  print "   'who' is the Redgifs username, ie. what comes after 'user/'\n   -i for Images (GIFs are default),\n   -a for both,\n   -s to skip existing,\n   -q for quiet mode,\n   -n for no clobber (files will gain .1, .2 and so on)\n\n";
  exit(-1);
}
get_recurse(undef,$who,\%opt);
