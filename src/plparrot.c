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

/**********************************************************************
 * The information we cache about loaded procedures
 **********************************************************************/
typedef struct plparrot_proc_desc
{
    char    *proname;       /* user name of procedure */
    TransactionId fn_xmin;
    ItemPointerData fn_tid;
    bool    fn_readonly;
    bool    lanpltrusted;
    bool    fn_retistuple;  /* true, if function returns tuple */
    bool    fn_retisset;    /* true, if function returns set */
    bool    fn_retisarray;  /* true if function returns array */
    Oid     result_oid;     /* Oid of result type */
    FmgrInfo    result_in_func; /* I/O function and arg for result type */
    Oid         result_typioparam;
    int         nargs;
    FmgrInfo    arg_out_func[FUNC_MAX_ARGS];
    bool        arg_is_rowtype[FUNC_MAX_ARGS];
   /* SV          *reference; */
} plparrot_proc_desc;

/*
 * The information we cache for the duration of a single call to a
 * function.
 */
typedef struct plparrot_call_data
{
    plparrot_proc_desc *prodesc;
    FunctionCallInfo fcinfo;
    Tuplestorestate *tuple_store;
    TupleDesc   ret_tdesc;
    AttInMetadata *attinmeta;
    MemoryContext tmp_cxt;
} plparrot_call_data;

int execq(text *sql, int cnt);
Parrot_Interp interp;

void
_PG_init(void)
{
    /* Be sure we do initialization only once */
    static bool inited = false;

    if (inited)
        return;

    interp = Parrot_new(NULL);
    imcc_initialize(interp);

    if (!interp) {
        elog(ERROR,"Could not create a Parrot interpreter!\n");
        return 1;
    }

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
Datum plparrot_func_handler(PG_FUNCTION_ARGS);

/* this is saved and restored by plparrot_call_handler */
static plparrot_call_data *current_call_data = NULL;


 /* The PostgreSQL function+trigger managers call this function for execution
    of PL/Parrot procedures. */

PG_FUNCTION_INFO_V1(plparrot_call_handler);

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    Datum retval;
    Form_pg_proc procstruct;
    HeapTuple proctup;
    Oid returntype;
    plparrot_call_data *save_call_data = current_call_data;

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
                /* we need a trigger handler */
        } else {
            retval = plparrot_func_handler(fcinfo);
        }
    }
    PG_CATCH();
    {
        current_call_data = save_call_data;
        PG_RE_THROW();
    }
    PG_END_TRY();

    current_call_data = save_call_data;

    /* Free our intrepreter */
    Parrot_destroy(interp);

    return retval;
}

Datum
plparrot_func_handler(PG_FUNCTION_ARGS)
{
    plparrot_proc_desc *prodesc;
    Datum   retval;
    ReturnSetInfo *rsi;
    ErrorContextCallback pl_error_context;
    /* what is the parrot equivalent of these?
    SV  *array_ret = NULL;
    SV  *perlret;
    */
    return retval;
}
