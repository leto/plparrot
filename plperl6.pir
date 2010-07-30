.sub run
    .param string code
    .param pmc args :slurpy
    args = convert_to_perl6_parcel(args)
    $S0 = "eval q<<< sub (@_) {"
    $S1 = "} >>>"
    code = $S0 . code
    code .= $S1
    load_bytecode 'dumper.pbc'
    print "About to run: "
    say code
    $P0 = compreg "perl6"
    $P1 = $P0.'compile'(code)
    say "args="
    _dumper(args)
    $P2 = $P1()
    $P3 = $P2(args)
    print "code returned: "
    _dumper($P3)
    say "=============="
    .return($P3)
.end

.sub convert_to_perl6_parcel
    .param pmc parrot_array
    .local pmc arrayizer, perl6_parcel

    # the infix comma operator, which creates Parcels from scalars
    arrayizer = get_root_global ['perl6'], '&infix:<,>'
    unless arrayizer goto error

    # pass a flattened array to the comma operator
    perl6_parcel = arrayizer(parrot_array :flat)
    .return(perl6_parcel)
  error:
    die "Could not turn Parrot array into a Perl 6 Parcel!"
.end
