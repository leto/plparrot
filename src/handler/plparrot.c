#include "postgres.h"
#include "executor/spi.h"
#include "commands/trigger.h"
#include "fmgr.h"
#include "access/heapam.h"
#include "utils/syscache.h"
#include "utils/builtins.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"

/*
Figure out how to include these properly

We need to use "parrot_config includedir"

#include "parrot/embed.h"
#include "parrot/debugger.h"
#include "parrot/runcore_api.h"
*/


PG_MODULE_MAGIC;
int execq(text *sql, int cnt);

int
execq(text *sql, int cnt)
{
    char *command;
    int ret;
    int proc;

    SPI_connect();

    SPI_finish();
    //pfree(command);

    return (proc);
}

Datum plparrot_call_handler(PG_FUNCTION_ARGS);
void plparrot_elog(int level, char *message);

PG_FUNCTION_INFO_V1(plparrot_call_handler);

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    Datum retval;

    retval = PG_GETARG_DATUM(0);
    PG_TRY();
    {
    }
    PG_CATCH();
    {
    }
    PG_END_TRY();

    return retval;
}

void
plparrot_elog(int level, char *message)
{
    elog(level, "%s", message);
}
