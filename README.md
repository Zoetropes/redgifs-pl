# redgifs-pl
Simple redgifs.com downloader in perl. Run from the commandline, options should be self-explanatory:

Usage: ./redgifs.pl [-i|a|s|n] <who>

   'who' is the Redgifs username, ie. what comes after 'user/'
   -i for Images (GIFs are default),
   -a for both,
   -s to skip existing,
   -q for quiet mode,
   -n for no clobber (files will gain .1, .2 and so on)
