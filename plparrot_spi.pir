.namespace ['PLParrot'; 'SPI']

.sub __spi_init :load
    loadlib $P1, ''

    # Global variables
    dlvar $P2, $P1, 'SPI_processed'
    set_global 'SPI_processed', $P2

    # Main interface
    # http://www.postgresql.org/docs/9.0/static/spi-interface.html
    dlfunc $P2, $P1, 'SPI_connect', 'i'
    set_global 'SPI_connect', $P2
    dlfunc $P2, $P1, 'SPI_finish', 'i'
    set_global 'SPI_finish', $P2
    dlfunc $P2, $P1, 'SPI_push', 'v'
    set_global 'SPI_push', $P2
    dlfunc $P2, $P1, 'SPI_pop', 'v'
    set_global 'SPI_pop', $P2
    dlfunc $P2, $P1, 'SPI_execute', 'itil'
    set_global 'SPI_execute', $P2
    dlfunc $P2, $P1, 'SPI_exec', 'itl'
    set_global 'SPI_exec', $P2
    dlfunc $P2, $P1, 'SPI_execute_with_args', 'itipppil'
    set_global 'SPI_execute_with_args', $P2
    dlfunc $P2, $P1, 'SPI_prepare', 'ptip'
    set_global 'SPI_prepare', $P2
    dlfunc $P2, $P1, 'SPI_prepare_cursor', 'ptipi'
    set_global 'SPI_prepare_cursor', $P2
    dlfunc $P2, $P1, 'SPI_prepare_params', 'ptppi'
    set_global 'SPI_prepare_params', $P2
    dlfunc $P2, $P1, 'SPI_getargcount', 'ip'
    set_global 'SPI_getargcount', $P2
    dlfunc $P2, $P1, 'SPI_getargtypeid', 'ipi'
    set_global 'SPI_getargtypeid', $P2
    dlfunc $P2, $P1, 'SPI_is_cursor_plan', 'ip'
    set_global 'SPI_is_cursor_plan', $P2
    dlfunc $P2, $P1, 'SPI_execute_plan', 'ipppil'
    set_global 'SPI_execute_plan', $P2
    dlfunc $P2, $P1, 'SPI_execute_plan_with_paramlist', 'ippil'
    set_global 'SPI_execute_plan_with_paramlist', $P2
    dlfunc $P2, $P1, 'SPI_execp', 'ipppl'
    set_global 'SPI_execp', $P2
    dlfunc $P2, $P1, 'SPI_cursor_open', 'ptpppi'
    set_global 'SPI_cursor_open', $P2
    dlfunc $P2, $P1, 'SPI_cursor_open_with_args', 'pttipppii'
    set_global 'SPI_cursor_open_with_args', $P2
    dlfunc $P2, $P1, 'SPI_cursor_open_with_paramlist', 'ptppi'
    set_global 'SPI_cursor_open_with_paramlist', $P2
    dlfunc $P2, $P1, 'SPI_cursor_find', 'pt'
    set_global 'SPI_cursor_find', $P2
    dlfunc $P2, $P1, 'SPI_cursor_fetch', 'vpil'
    set_global 'SPI_cursor_fetch', $P2
    dlfunc $P2, $P1, 'SPI_cursor_move', 'vpil'
    set_global 'SPI_cursor_move', $P2
    dlfunc $P2, $P1, 'SPI_scroll_cursor_fetch', 'vpil'
    set_global 'SPI_scroll_cursor_fetch', $P2
    dlfunc $P2, $P1, 'SPI_scroll_cursor_move', 'vpil'
    set_global 'SPI_scroll_cursor_move', $P2
    dlfunc $P2, $P1, 'SPI_cursor_close', 'vp'
    set_global 'SPI_cursor_close', $P2
    dlfunc $P2, $P1, 'SPI_saveplan', 'pp'
    set_global 'SPI_saveplan', $P2

    # Support interface not currently possible, until libffi support
    # is added to Parrot's NCI
    # http://www.postgresql.org/docs/9.0/static/spi-interface-support.html
    # http://www.parrot.org/content/gsoc-nci-updates
    # http://github.com/ashgti/parrot

    # Memory management interface
    # http://www.postgresql.org/docs/9.0/static/spi-memory.html
    dlfunc $P2, $P1, 'SPI_palloc', 'pl'
    set_global 'SPI_palloc', $P2
    dlfunc $P2, $P1, 'SPI_repalloc', 'ppl'
    set_global 'SPI_repalloc', $P2
    dlfunc $P2, $P1, 'SPI_pfree', 'vp'
    set_global 'SPI_pfree', $P2

    # The following functions are not implementable yet, due to the same issue
    # as the 'support interface' above:
    #   SPI_copytuple
    #   SPI_returntuple
    #   SPI_modifytuple
    #   SPI_freetuple

    dlfunc $P2, $P1, 'SPI_freetuptable', 'vp'
    set_global 'SPI_freetuptable', $P2
    dlfunc $P2, $P1, 'SPI_freeplan', 'ip'
    set_global 'SPI_freeplan', $P2

    # Other functions
    dlfunc $P2, $P1, 'elog_start', 'vtit'
    set_global 'elog_start', $P2
    dlfunc $P2, $P1, 'elog_finish', 'vit'
    set_global 'elog_finish', $P2
.end

######################
## Public interface ##
######################

# We're going to mimic the pl/perl SPI interface for now:
#    http://www.postgresql.org/docs/8.4/static/plperl-database.html
#
# This interface isn't actually very nice, and something more DBI-ish
# would be much better, but this is good for a first iteration, and
# is compatible and familiar to people already using pl/perl

# spi_exec_query(query [, max-rows])
.sub spi_exec_query
.end

# spi_query(command)
.sub spi_query
.end

# spi_fetchrow(cursor)
.sub spi_fetchrow
.end

# spi_cursor_close(cursor)
.sub spi_cursor_close
.end

# spi_prepare(command, argument types)
.sub spi_prepare
.end

# spi_query_prepared(plan, arguments)
.sub spi_query_prepared
.end

# spi_exec_prepared(plan [, attributes], arguments)
.sub spi_exec_prepared
.end

# spi_freeplan(plan)
.sub spi_freeplan
.end

# elog(level, msg)
.sub elog
    .param int level
    .param string msg

    .local pmc elog_start, elog_finish
    elog_start = get_global 'elog_start'
    elog_finish = get_global 'elog_finish'

    # Ideally we'd want this data from the caller, if we can get it (file, line, func)
    elog_start('plparrot_spi.pir', 117, 'elog')
    elog_finish(level, msg)

    # plperl does some fiddly stuff with MemoryContextSwitchTo, CopyErrorData,
    # and FlushErrorState if there's an error trying to elog.  We should probably
    # consider doing it here too
.end
