.sub run
    .param string code
    $S0 = "my $r = eval q<<<\nsub {"
    $S1 = "}\n>>>; $r.()"
    code = $S0 . code
    code .= $S1
    load_bytecode 'dumper.pbc'
    print "About to run: "
    say code
    $P0 = compreg "perl6"
    $P1 = $P0.'compile'(code)
    $P2 = $P1()
    print "code returned: "
    _dumper($P2)
    .return($P2)
.end
