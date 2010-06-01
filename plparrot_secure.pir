.sub _ :main
    .loadlib "io_ops"
    .local pmc p6meta, interp, classes, classid
    p6meta = get_root_global ["parrot"], "P6metaclass"
    p6meta.'new_class'('PLParrot')

    interp = getinterp
    classes = interp[0]
    classid = classes['PLParrot']

    # Replace these classes with our PLParrot class
    set classes['FileHandle'], classid
    set classes['File'], classid
.end

.namespace ["PLParrot"]
.sub open :method
    .param pmc args :slurpy
    # die "Attempt to open "
    .return(42)
.end

.sub copy :method
    .param pmc from
    .param pmc to
    print "Attempt to copy file "
    print from
    print "="
    say to
.end

.sub rename :method
    .param pmc from
    .param pmc to
    print "Attempt to rename file "
    print from
    print " to "
    say to
.end

