=head1 NAME

Glue.pir - Rakudo "glue" builtins (functions/globals) converted for NQP


=head1 SYNOPSIS

    # Load this library
    load_bytecode('src/lib/Glue.pbc');

    # External programs
    $status_code := run(   $command, $and, $args, ...);
    $success     := do_run($command, $and, $args, ...);
    $output      := qx(    $command, $and, $args, ...);

    # Exceptions
    die($message);
    try(&code, @args [, &handler]);

    # Hash basics
    @keys  := keys(%hash);
    $found := exists(%hash, $key);

    # OO and types
    $does_role := does($object, $role);

    # I/O
    $contents := slurp($filename);
    spew(  $filename, $contents);
    append($filename, $contents);

    # Regular expressions
    $regex_object := rx($regex_source);
    @matches := all_matches($regex, $text);
    $edited := subst($original, $regex, $replacement);

    # Filesystems and paths
    chdir($path);
    $path  := cwd();
    mkdir($path [, $mode]);
    unlink($path);
    @info  := stat($path);
    $found := path_exists($path);
    @names := readdir($directory);
    $path  := fscat(@path_parts [, $filename]);

    # String basics
    $joined := join($delimiter, @strings);
    @pieces := split($delimiter, $original);

    # Context
    @array  := as_array($list, $of, $items, ...);
    $result := call_flattened(&code, $mixed, @args, $list, ...);

    # Global variables;
    our $PROGRAM_NAME;
    our @ARGS;
    our %ENV;
    our %VM;
    our $OS;
    our $OSVER;

    
=cut

.namespace []

.include 'interpinfo.pasm'
.include 'sysinfo.pasm'
.include 'iglobals.pasm'


=head1 DESCRIPTION

=head2 Functions

=over 4

=item $status_code := run($command, $and, $args, ...)

Spawn the command with the given arguments as a new process; returns
the status code of the spawned process, which is equal the the result
of the waitpid system call, right bitshifted by 8.

=cut

.sub 'run'
    .param pmc command_and_args :slurpy
    .local int status

    # returns the result of waitpid
    status = spawnw command_and_args

    # return code is waitpid >> 8
    shr status, status, 8

    .return (status)
.end


=item $success := do_run($command, $and, $args, ...)

Print out the command and arguments, then spawn the command with the given
arguments as a new process; return 1 if the process exited successfully, or
0 if not.

=cut

.sub 'do_run'
    .param pmc command_and_args :slurpy

    .local string cmd
    cmd = join ' ', command_and_args
    say cmd

    .local int status
    status = spawnw command_and_args

    if status goto failed
    .return (1)
  failed:
    .return (0)
.end


=item $output := qx($command, $and, $args, ...)

Spawn the command with the given arguments as a read only pipe;
return the output of the command as a single string.

B<WARNING>: Parrot currently implements this B<INSECURELY>!

=cut

.sub 'qx'
    .param pmc command_and_args :slurpy

    .local string cmd
    cmd = join ' ', command_and_args

    .local pmc pipe
    pipe = open cmd, 'rp'
    unless pipe goto pipe_open_error

    .local pmc output
    pipe.'encoding'('utf8')
    output = pipe.'readall'()
    pipe.'close'()
    .return (output)

  pipe_open_error:
    $S0  = 'Unable to execute "'
    $S0 .= cmd
    $S0 .= '"'
    die $S0
.end


=item die($message)

Kill program, reporting error C<$message>.

=cut

.sub 'die'
    .param string message

    die message
.end


=item $ret := try(&code, @args [, &handler])

Call C<&code> with flattened C<@args>.  If there are any exceptions, catch
them and invoke C<&handler> with the exception, C<&code>, and C<@args>.
If C<&handler> is absent, simply return C<0> if an exception is caught.
In other words, C<try()> implements the following pseudocode:

    try        { $ret := &code(|@args)                                }
    catch($ex) { $ret := &handler ?? &handler($ex, &code, @args) !! 0 }
    return $ret;

=cut

.sub 'try'
    .param pmc code
    .param pmc args
    .param pmc handler :optional
    .param int has_handler :opt_flag

    push_eh do_handler
    $P0 = code(args :flat)
    pop_eh
    .return ($P0)

  do_handler:
    .local pmc ex
    .get_results (ex)
    pop_eh
    eq has_handler, 0, no_handler
    $P0 = handler(ex, code, args)
    .return ($P0)

  no_handler:
    .return (0)
.end


=item @keys := keys(%hash)

Return an array containing the keys of the C<%hash>.

=cut

.sub 'keys'
    .param pmc hash

    .local pmc key_list, it
    key_list = root_new ['parrot';'ResizableStringArray']
    it       = iter hash

  key_loop:
    unless it goto no_more_keys

    $S0 = shift it
    push key_list, $S0

    goto key_loop
  no_more_keys:

    .return(key_list)
.end


=item $found := exists(%hash, $key)

Determine if C<$key> exists in C<%hash>, returning a true value if so, and a
false value if not.

=cut

.sub 'exists'
    .param pmc    hash
    .param string key

    $I0 = exists hash[key]

    .return($I0)
.end


=item $does_role := does($object, $role)

Determine if C<$object> does the C<$role>, returning a true value if so, and a
false value if not.

=cut

.sub 'does'
    .param pmc    object
    .param string role

    $I0 = does object, role

    .return($I0)
.end


=item $contents := slurp($filename)

Read the C<$contents> of a file as a single string.

=cut

.sub 'slurp'
    .param string filename
    .local string contents

    $P0 = open filename, 'r'
    contents = $P0.'readall'()
    close $P0
    .return(contents)
.end


=item spew($filename, $contents)

Write the string C<$contents> to a file.

=cut

.sub 'spew'
    .param string filename
    .param string contents

    $P0 = open filename, 'w'
    $P0.'print'(contents)
    close $P0
.end


=item append($filename, $contents)

Append the string C<$contents> to a file.

=cut

.sub 'append'
    .param string filename
    .param string contents

    $P0 = open filename, 'a'
    $P0.'print'(contents)
    close $P0
.end


=item $regex_object := rx($regex_source)

Compile C<$regex_source> (a string representing the source code form of a
Perl 6 Regex) into a C<$regex_object>, suitable for using in C<match()> and
C<subst()>.

=cut

.sub 'rx'
    .param string source

    .local pmc p6regex, object
    p6regex = compreg 'PGE::Perl6Regex'
    object  = p6regex(source)

    .return(object)
.end

=item @matches := all_matches($regex, $text)

Find all matches (C<:g> style, not C<:exhaustive>) for C<$regex> in the
C<$text>.  The C<$regex> must be a regex object returned by C<rx()>.

=cut

.sub 'all_matches'
    .param pmc    regex
    .param string text

    # Find all matches in the original string
    .local pmc matches, match
    matches = root_new ['parrot';'ResizablePMCArray']
    match   = regex(text)
    unless match goto done_matching

  match_loop:
    push matches, match

    $I0   = match.'to'()
    match = regex(match, 'continue' => $I0)

    unless match goto done_matching
    goto match_loop
  done_matching:

    .return(matches)
.end


=item $edited := subst($original, $regex, $replacement)

Substitute all matches of the C<$regex> in the C<$original> string with the
C<$replacement>, and return the edited string.  The C<$regex> must be a regex
object returned by the C<rx()> function.

The C<$replacement> may be either a simple string or a sub that will be called
with each match object in turn, and must return the proper replacement string
for that match.

=cut

.sub 'subst'
    .param string original
    .param pmc    regex
    .param pmc    replacement

    # Find all matches in the original string
    .local pmc matches
    matches = all_matches(regex, original)

    # Do the substitutions on a clone of the original string
    .local string edited
    edited = clone original

    # Now replace all the matched substrings
    .local pmc match
    .local int offset
    offset = 0
  replace_loop:
    unless matches goto done_replacing
    match = shift matches

    # Handle either string or sub replacement
    .local string replace_string
    $I0 = isa replacement, 'Sub'
    if $I0 goto call_replacement_sub
    replace_string = replacement
    goto have_replace_string
  call_replacement_sub:
    replace_string = replacement(match)
  have_replace_string:

    # Perform the replacement
    $I0  = match.'from'()
    $I1  = match.'to'()
    $I2  = $I1 - $I0
    $I0 += offset
    substr edited, $I0, $I2, replace_string
    $I3  = length replace_string
    $I3 -= $I2
    offset += $I3
    goto replace_loop
  done_replacing:

    .return(edited)
.end

=item chdir($path)

Change the current working directory to the specified C<$path>.

=cut

.sub 'chdir'
    .param string path

    .local pmc os
    os = root_new [ 'parrot' ; 'OS' ]
    os.'chdir'(path)
.end

=item $path := cwd()

Return the current working directory.

=cut

.sub 'cwd'
    .local pmc os
    os = root_new [ 'parrot' ; 'OS' ]

    .local string path
    path = os.'cwd'()

    .return(path)
.end

=item mkdir($path [, $mode])

Create a directory specified by C<$path> with mode C<$mode>.  C<$mode> is
optional and defaults to octal C<777> (full permissions) if absent.  C<$mode>
is modified by the user's current C<umask> as usual.

=cut

.sub 'mkdir'
    .param string path
    .param int    mode     :optional
    .param int    has_mode :opt_flag

    if has_mode goto have_mode
    mode = 0o777
  have_mode:

    .local pmc os
    os = root_new [ 'parrot' ; 'OS' ]
    os.'mkdir'(path, mode)
.end

=item unlink($path)

Unlink (delete) a file or empty directory named C<$path> in the filesystem.

=cut

.sub 'unlink'
    .param string path

    .local pmc os
    os = root_new [ 'parrot' ; 'OS' ]
    os.'rm'(path)
.end

=item @info := stat($path)

Returns a 13-item list of information about the given C<$path>, as in Perl 5.
(See C<perldoc -f stat> for more details.)

=cut

.sub 'stat'
    .param string path

    .local pmc os, stat_list
    os = root_new [ 'parrot' ; 'OS' ]
    stat_list = os.'stat'(path)

    .return (stat_list)
.end

=item $found := path_exists($path);

Return a true value if the C<$path> exists on the filesystem, or a false
value if not.

=cut

.sub 'path_exists'
    .param string path

    push_eh stat_failed
    .local pmc stat_list
    stat_list = 'stat'(path)
    pop_eh
    .return (1)

  stat_failed:
    pop_eh
    .return (0)
.end

=item @names := readdir($directory)

List the names of all entries in the C<$directory>.

=cut

.sub 'readdir'
    .param string dir

    .local pmc os, names
    os = root_new [ 'parrot' ; 'OS' ]
    names = os.'readdir'(dir)

    .return (names)
.end

=item $path := fscat(@path_parts [, $filename])

Join C<@path_parts> and C<$filename> strings together with the appropriate
OS separator.  If no C<$filename> is supplied, C<fscat()> will I<not> add a
trailing slash (though slashes inside the C<@path_parts> will not be removed,
so don't do that).

=cut

.sub 'fscat'
    .param pmc    parts
    .param string filename     :optional
    .param int    has_filename :opt_flag

    .local string sep
    $P0 = getinterp
    $P1 = $P0[.IGLOBALS_CONFIG_HASH]
    sep = $P1['slash']

    .local string joined
    joined = join sep, parts

    unless has_filename goto no_filename
    joined .= sep
    joined .= filename
  no_filename:

    .return (joined)
.end

=item $joined := join($delimiter, @strings)

Join C<@strings> together with the specified C<$delimiter>.

=cut

.sub 'join'
    .param string delim
    .param pmc    strings

    .local string joined
    joined = join delim, strings

    .return (joined)
.end

=item @pieces := split($delimiter, $original)

Split the C<$original> string with the specified C<$delimiter>, which is not
included in the resulting C<@pieces>.

=cut

.sub 'split'
    .param string delim
    .param string original

    .local pmc pieces
    pieces = split delim, original

    .return (pieces)
.end


=item @array := as_array($list, $of, $items, ...)

Slurp the list of arguments into an array and return it.

=cut

.sub 'as_array'
     .param pmc items :slurpy

     .return (items)
.end


=item $result := call_flattened(&code, $mixed, @args, $list, ...)

Call C<&code> with flattened arguments.  This is done by first slurping all
arguments into an array, then iterating over the array flattening by one level
each element that C<does 'array'>.  Finally, the C<&code> is tailcalled with
the flattened array using the Parrot C<:flat> flag.

To avoid flattening an array that should be passed as a single argument, wrap
it with C<as_array()> first, like so:

    call_flattened(&code, as_array(@protected), @will_flatten)

=cut

.sub 'call_flattened'
    .param pmc code
    .param pmc args :slurpy

    .local pmc flattened, args_it, array_it
    flattened = root_new ['parrot';'ResizablePMCArray']
    args_it   = iter args

  args_loop:
    unless args_it goto do_tailcall
    $P0 = shift args_it
    $I0 = does $P0, 'array'
    if $I0 goto flatten_array
    push flattened, $P0
    goto args_loop
  flatten_array:
    array_it = iter $P0
  array_loop:
    unless array_it goto args_loop
    $P1 = shift array_it
    push flattened, $P1
    goto array_loop

  do_tailcall:
    .tailcall code(flattened :flat)
.end

=back


=head2 Global Variables

=over 4

=item $PROGRAM_NAME

Name of running program (argv[0] in C)

=item @ARGS

Program's command line arguments (including options, which are NOT parsed)

=item %VM

Parrot configuration

=item %ENV

Process-wide environment variables

=item $OS

Operating system generic name

=item $OSVER

Operating system version

=back

=cut

.sub 'onload' :anon :load :init
    load_bytecode 'config.pbc'
    $P0 = getinterp
    $P1 = $P0[.IGLOBALS_CONFIG_HASH]
    $P2 = new ['Hash']
    $P2['config'] = $P1
    set_hll_global '%VM', $P2

    $P1 = $P0[.IGLOBALS_ARGV_LIST]
    if $P1 goto have_args
    unshift $P1, '<anonymous>'
  have_args:
    $S0 = shift $P1
    $P2 = box $S0
    set_hll_global '$PROGRAM_NAME', $P2
    set_hll_global '@ARGS', $P1

    $P0 = root_new ['parrot';'Env']
    set_hll_global '%ENV', $P0

    $S0 = sysinfo .SYSINFO_PARROT_OS
    $P0 = box $S0
    set_hll_global '$OS', $P0

    $S0 = sysinfo .SYSINFO_PARROT_OS_VERSION
    $P0 = box $S0
    set_hll_global '$OSVER', $P0
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
