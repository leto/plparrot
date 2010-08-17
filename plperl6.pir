.sub run
    .param string code
    .param pmc args :slurpy
    .local pmc perl6_args

    perl6_args = convert_to_perl6_parcel(args)
    .local string wrap_start, wrap_end
    wrap_start = "eval q<<< sub "
    wrap_end   = " >>>"
    code = wrap_start . code
    code .= wrap_end
    load_bytecode 'dumper.pbc'
    print "About to run: "
    say code

    .local pmc compiler, function, output
    compiler = compreg "perl6"
    function = compiler.'compile'(code)
    say "args="
    _dumper(perl6_args)
    output = function()
    .local int nullargs
    nullargs = isnull perl6_args
    if nullargs goto call_with_empty_args
    $P3 = output(perl6_args)
 call_with_empty_args:
    $P3 = output()
    $I0 = isa $P3, "Block"
    unless $I0 goto done
    # the output of running the function returned a Block,
    # such as a pointy block -> $a, $b { }, so let's go ahead
    # and execute that
    $P3 = $P3(perl6_args)
  done:
    print "code returned: "
    _dumper($P3)
    say "=============="
    .return($P3)
.end

.sub convert_to_perl6_parcel
    .param pmc parrot_array
    .local pmc arrayizer, perl6_parcel

    unless parrot_array goto empty

    # the infix comma operator, which creates Parcels from scalars
    arrayizer = get_root_global ['perl6'], '&infix:<,>'
    unless arrayizer goto error

    # pass a flattened array to the comma operator
    perl6_parcel = arrayizer(parrot_array :flat)
    .return(perl6_parcel)
  error:
    die "Could not turn Parrot array into a Perl 6 Parcel!"
  empty:
    say "EMTPY!"
    .return()
.end
