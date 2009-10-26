###
### HACKS
###


# NQP bug XXXX: Fakecutables broken because 'nqp' language is not loaded.
Q:PIR{
    $P0 = get_hll_global 'say'
  unless null $P0 goto got_nqp
    load_language 'nqp'
  got_nqp:
};

# NQP bug XXXX: Must redeclare PIR globals because the NQP parser can't
#               know about variables created at load_bytecode time.
our $PROGRAM_NAME;
our @ARGS;
our %ENV;
our %VM;
our $OS;


# NQP does not automatically call MAIN()
MAIN();

###
### MAIN
###


sub MAIN () {
    say("Hello");
    print(version_info());
}

sub version_info () {
    my $version := '0';
    return
'This is PL/Parrot, version ' ~ $version ~ '.

Copyright (C) 2009, Parrot Foundation.

This code is distributed under the terms of the Artistic License 2.0.
For more details, see the full text of the license in the LICENSE file
included in the PL/Parrot source tree.
';
}

