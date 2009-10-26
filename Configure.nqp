# Purpose: Use Parrot's config info to configure our Makefile.
#
# Usage:
#     parrot_nqp Configure.nqp [input_makefile [output_makefile]]
#
# input_makefile  defaults to 'Makefile.in';
# output_makefile defaults to 'Makefile'.

our @ARGS;
our %VM;
our $OS;

MAIN();

sub MAIN () {
    # Wave to the friendly users
    say("Hello, I'm Configure. My job is to poke and prod\nyour system to figure out how to build PL/Parrot.\n");

    # Load Parrot config and glue functions
    load_bytecode('src/lib/Glue.pir');

    # Slurp in the unconfigured Makefile text
    my $unconfigured := slurp(@ARGS[0] || 'src/Makefile.in');

    # Replace all of the @foo@ markers
    my $replaced := subst($unconfigured, rx('\@<ident>\@'), replacement);

    # Fix paths on Windows
    if ($OS eq 'MSWin32') {
        $replaced := subst($replaced, rx('/'), '\\');
    }

    # Spew out the final makefile
    spew(@ARGS[1] || 'Makefile', $replaced);

    # Give the user a hint of next action
    say("Configure completed for platform '" ~ $OS ~ "'.");
    say("You can now type '" ~ %VM<config><make> ~ "' to build PL/Parrot.\n");
    say("You may also type '" ~ %VM<config><make> ~ " test' to run the PL/Parrot test suite.\n");
    say("Happy Hacking,\n\tThe PL/Parrot Team");
}

sub replacement ($match) {
    my $key    := $match<ident>;
    my $config := %VM<config>{$key} || '';

    return $config;
}
