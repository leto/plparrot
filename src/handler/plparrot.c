/* Parrot header files */
#include "parrot/embed.h"
#include "parrot/extend.h"

/* Postgres header files */
#include "postgres.h"
#include "access/heapam.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"
#include "executor/spi.h"
#include "commands/trigger.h"
#include "funcapi.h"
#include "fmgr.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "parser/parse_type.h"
#include "tcop/tcopprot.h"
#include "utils/builtins.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/syscache.h"
#include "utils/typcache.h"


#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

int execq(text *sql, int cnt);

void
_PG_init(void)
{
    /* Be sure we do initialization only once */
    static bool inited = false;

    if (inited)
        return;

    inited = true;
}

int
execq(text *sql, int cnt)
{
    char *command;
    int proc;
    int ret;

    if (SPI_connect() != SPI_OK_CONNECT)
        ereport(ERROR, (errcode(ERRCODE_CONNECTION_EXCEPTION), errmsg("Couldn't connect to SPI")));

    /* Convert given text object to a C string */
    command = DatumGetCString(DirectFunctionCall1(textout, PointerGetDatum(sql)));

    ret = SPI_exec(command, cnt);

    proc = SPI_processed;

    /* do stuff */

    SPI_finish();
    pfree(command);

    return (proc);
}

Datum plparrot_call_handler(PG_FUNCTION_ARGS);
void plparrot_elog(int level, char *message);

PG_FUNCTION_INFO_V1(plparrot_call_handler);

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    Datum retval;
    Form_pg_proc procstruct;
    HeapTuple proctup;
    Oid returntype;
    Parrot_Interp interp;

    interp = Parrot_new(NULL);
    if (!interp) {
        elog(ERROR,"Could not create a Parrot interpreter!\n");
        return 1;
    }

    proctup = SearchSysCache(PROCOID, ObjectIdGetDatum(fcinfo->flinfo->fn_oid), 0, 0, 0);
    if (!HeapTupleIsValid(proctup))
        elog(ERROR, "Failed to look up procedure with OID %u", fcinfo->flinfo->fn_oid);
    procstruct = (Form_pg_proc) GETSTRUCT(proctup);
    returntype = procstruct->prorettype;

    /* procstruct probably isn't valid after this ReleaseSysCache call, so don't use it */
    ReleaseSysCache(proctup);

    if (returntype == VOIDOID)
        PG_RETURN_VOID();

    if (fcinfo->nargs == 0)
        PG_RETURN_NULL();

    /* Assume from here on out that the first argument type is the same as the return type */
    retval = PG_GETARG_DATUM(0);

    PG_TRY();
    {
        if (CALLED_AS_TRIGGER(fcinfo)) {
                TriggerData *tdata = (TriggerData *) fcinfo->context;
        }
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
