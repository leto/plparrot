.sub run
    .param string code
    print "About to run: "
    say code
    $P0 = compreg "perl6"
    $P1 = $P0.'compile'(code)
    $P2 = $P1()
    print "code returned: "
    say $P2
    .return($P2)
.end
