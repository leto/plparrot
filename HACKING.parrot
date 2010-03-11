Here's a way to have fresh parrots.

export PATH=$HOME/installed_parrot/bin:$PATH
alias new_parrot="make realclean; perl Configure.pl --optimize --prefix=$HOME/installed_parrot && nice -n20 gmake -j"
