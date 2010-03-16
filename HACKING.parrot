Here's a way to have fresh parrots.

Figure out what to put in instead of -j4 by figuring out how many
cores are available.  On Linux, you can cat /proc/cpuinfo.

export PATH=$HOME/installed_parrot/bin:$PATH
alias new_parrot="make realclean; perl Configure.pl --optimize --prefix=$HOME/installed_parrot && nice -n20 gmake -j4"
