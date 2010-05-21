#include "plparrot.h"
#include "config.h"

/* Parrot header files */
#include "parrot/embed.h"
#include "parrot/extend.h"
#include "parrot/imcc.h"
#include "parrot/extend_vtable.h"
#include "parrot/config.h"

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
#if PG_VERSION_NUM >= 80500
#include "utils/bytea.h"
#endif



#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

#ifdef TextDatumGetCString
#define TextDatum2String(x) (pstrdup(TextDatumGetCString(x)))
#else
    /* For PostgreSQL versions 8.3 and prior */
#define TextDatum2String(X) (pstrdup(DatumGetCString(DirectFunctionCall1(textout, (X)))))
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

Parrot_Interp interp, untrusted_interp, trusted_interp;

/* Helper functions */
Parrot_String create_string(const char *name);
Parrot_String create_string_const(const char *name);

Parrot_PMC create_pmc(const char *name);
Datum       plparrot_make_sausage(Parrot_Interp interp, Parrot_PMC pmc, FunctionCallInfo fcinfo);
void plparrot_secure(Parrot_Interp interp);

void plparrot_push_pgdatatype_pmc(Parrot_PMC, FunctionCallInfo, int);

/* this is saved and restored by plparrot_call_handler */
static plparrot_call_data *current_call_data = NULL;

/* Be sure we do initialization only once */
static bool inited = false;

void _PG_init(void);
void _PG_fini(void);

void
_PG_init(void)
{
    if (inited)
        return;


    untrusted_interp = Parrot_new(NULL);
    imcc_initialize(untrusted_interp);

    /* Must use the first created interp as the parent of subsequently created interps */
    trusted_interp = Parrot_new(untrusted_interp);
    imcc_initialize(trusted_interp);

    //Parrot_set_trace(interp, PARROT_ALL_TRACE_FLAGS);

    if (!trusted_interp) {
        elog(ERROR,"Could not create a trusted Parrot interpreter!\n");
        return;
    }
    if (!untrusted_interp) {
        elog(ERROR,"Could not create an untrusted Parrot interpreter!\n");
        return;
    }
    interp = trusted_interp;
    plparrot_secure(interp);

    inited = true;
}

/*
 *  Per PostgreSQL 9.0 documentation, _PG_fini only gets called when a module
 *  is un-loaded, which isn't yet supported. But I'm putting this here for good
 *  measure, anyway
 */
void
_PG_fini(void)
{
    Parrot_destroy(trusted_interp);
    Parrot_destroy(untrusted_interp);

    inited = false;
}

Datum plparrot_call_handler(PG_FUNCTION_ARGS);
Datum plparrotu_call_handler(PG_FUNCTION_ARGS);
static Datum plparrot_func_handler(PG_FUNCTION_ARGS);
static Datum plparrotu_func_handler(PG_FUNCTION_ARGS);

 /* The PostgreSQL function+trigger managers call this function for execution
    of PL/Parrot procedures. */

PG_FUNCTION_INFO_V1(plparrot_call_handler);
PG_FUNCTION_INFO_V1(plparrotu_call_handler);

static Datum
plparrotu_func_handler(PG_FUNCTION_ARGS)
{
    interp = untrusted_interp;
    return plparrot_func_handler(fcinfo);
    interp = trusted_interp;
}

/*
 * The PostgreSQL function+trigger managers call this function for execution of
 * PL/Parrot procedures.
 */

static Datum
plparrot_func_handler(PG_FUNCTION_ARGS)
{
    Parrot_PMC func_pmc, func_args, result, tmp_pmc;
    Parrot_String err;
    Datum retval, procsrc_datum;
    Form_pg_proc procstruct;
    HeapTuple proctup;
    Oid returntype, *argtypes;

    int numargs, rc, i, length;
    char *proc_src, *errmsg, *tmp;
    char *pir_src;
    char pir_begin[13] = ".sub p :anon";
    char pir_end[4]    = ".end";
    char **argnames, *argmodes;
    bool isnull;

    if ((rc = SPI_connect()) != SPI_OK_CONNECT)
        elog(ERROR, "SPI_connect failed: %s", SPI_result_code_string(rc));

    retval = PG_GETARG_DATUM(0);

    proctup = SearchSysCache(PROCOID, ObjectIdGetDatum(fcinfo->flinfo->fn_oid), 0, 0, 0);
    if (!HeapTupleIsValid(proctup))
        elog(ERROR, "Failed to look up procedure with OID %u", fcinfo->flinfo->fn_oid);
    procstruct = (Form_pg_proc) GETSTRUCT(proctup);
    returntype = procstruct->prorettype;
    procsrc_datum = SysCacheGetAttr(PROCOID, proctup, Anum_pg_proc_prosrc, &isnull);
    numargs = get_func_arg_info(proctup, &argtypes, &argnames, &argmodes);


    if (isnull)
        elog(ERROR, "Couldn't load function source for function with OID %u", fcinfo->flinfo->fn_oid);

    /* procstruct probably isn't valid after this ReleaseSysCache call, so don't use it anymore */
    ReleaseSysCache(proctup);
    proc_src = TextDatum2String(procsrc_datum);
    length   = strlen(proc_src);
    pir_src = malloc( 13 + length + 4 );
    memcpy(pir_src, pir_begin, 13);
    /* This should have a sane default and be configurable */
    strncat(pir_src, proc_src, MAX_SUBROUTINE_LENGTH);
    strncat(pir_src, pir_end, 4);

    /* elog(NOTICE,"about to compile a PIR string: %s", pir_src); */
    /* Our current plan of attack is the pass along a ResizablePMCArray to all stored procedures */
    func_pmc  = Parrot_compile_string(interp, create_string_const("PIR"), pir_src, &err);

    free(pir_src);

    func_args = create_pmc("ResizablePMCArray");

    for (i = 0; i < numargs; i++) {
        plparrot_push_pgdatatype_pmc(func_args, fcinfo, i);
    }

    /* elog(NOTICE,"compiled a PIR string"); */
    if (!Parrot_str_is_null(interp, err)) {
        /* elog(NOTICE,"got an error compiling PIR string"); */
        tmp = Parrot_str_to_cstring(interp, err);
        errmsg = pstrdup(tmp);
        /* elog(NOTICE,"about to free parrot cstring"); */
        Parrot_str_free_cstring(tmp);
        elog(ERROR, "Error compiling PIR function: %s", errmsg);
    }
    /* elog(NOTICE,"about to call compiled PIR string with Parrot_ext_call"); */
    /* See Parrot's src/extend.c for interpretations of the third argument */
    /* Pf => PMC with :flat attribute */
    /* Return value of the function call is stored in result */

    result = create_pmc("ResizablePMCArray");
    Parrot_ext_call(interp, func_pmc, "Pf->Pf", func_args, &result);

    /* Where is the correct place to put this? */
    if ((rc = SPI_finish()) != SPI_OK_FINISH)
        elog(ERROR, "SPI_finish failed: %s", SPI_result_code_string(rc));

    if (Parrot_PMC_get_bool(interp,result)) {
        tmp_pmc = Parrot_PMC_pop_pmc(interp, result);
        retval = plparrot_make_sausage(interp,tmp_pmc,fcinfo);
    } else {
        /* We got an empty array of return values, so we should return void */
        PG_RETURN_VOID();
    }

    return retval;
}
void
plparrot_push_pgdatatype_pmc(Parrot_PMC func_args, FunctionCallInfo fcinfo, int i)
{
        int16 typlen;
        char typalign;
        bool typbyval;
        Oid element_type = get_fn_expr_argtype(fcinfo->flinfo, i);

        if (!OidIsValid(element_type))
            elog(ERROR, "could not determine data type of input");

        /* This info is currently unused */
        get_typlenbyvalalign(element_type, &typlen, &typbyval, &typalign);

        /* XXX: Need to handle null arguments. Test with PG_ARGISNULL(argument_number) */
        switch (element_type) {
            case TEXTOID:
            case CHAROID:
            case VARCHAROID:
            case BPCHAROID:
                Parrot_PMC_push_string(interp, func_args, create_string(TextDatum2String(PG_GETARG_DATUM(i))));
                break;
            case INT2OID:
                Parrot_PMC_push_integer(interp, func_args, (Parrot_Int) PG_GETARG_INT16(i));
                break;
            case INT4OID:
                Parrot_PMC_push_integer(interp, func_args, (Parrot_Int) PG_GETARG_INT32(i));
                break;
            case INT8OID:
                /* XXX: Loss of precision here? */
                Parrot_PMC_push_integer(interp, func_args, (Parrot_Int) PG_GETARG_INT64(i));
                break;
            case FLOAT4OID:
                Parrot_PMC_push_float(interp, func_args, (Parrot_Float) PG_GETARG_FLOAT4(i));
                break;
            case FLOAT8OID:
                Parrot_PMC_push_float(interp, func_args, (Parrot_Float) PG_GETARG_FLOAT8(i));
                break;
            /* We need custom PMCs for these, and each Postgres data type */
            case TIMESTAMPOID:
            case TIMESTAMPTZOID:
            case TIMEOID:
                Parrot_PMC_push_float(interp, func_args, (Parrot_Float) PG_GETARG_FLOAT8(i));
                break;
            default:
                elog(ERROR,"PL/Parrot does not know how to convert the %u element type", element_type);
        }
}

Datum
plparrotu_call_handler(PG_FUNCTION_ARGS)
{
    interp = untrusted_interp;
    plparrot_call_handler(fcinfo);
    interp = trusted_interp;
}

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    Datum retval = 0;
    TriggerData *tdata;
    plparrot_call_data *save_call_data = current_call_data;

    PG_TRY();
    {
        if (CALLED_AS_TRIGGER(fcinfo)) {
            tdata = (TriggerData *) fcinfo->context;
            /* TODO: we need a trigger handler */
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

    return retval;
}

void plparrot_secure(Parrot_Interp interp)
{
    Parrot_PMC func_pmc;
    Parrot_String err;
    char *p6class = PARROTP6OBJECT;

    Parrot_load_bytecode(interp,create_string_const(p6class));

    func_pmc  = Parrot_compile_string(interp, create_string_const("PIR"), PLPARROT_SECURE, &err);
    Parrot_ext_call(interp, func_pmc, "->");
}

Parrot_PMC  create_pmc(const char *name)
{
    return Parrot_PMC_new(interp,Parrot_PMC_typenum(interp,name));
}

Parrot_String create_string(const char *name)
{
    return Parrot_str_new(interp, name, strlen(name));
}

Parrot_String create_string_const(const char *name)
{
    return Parrot_str_new_constant(interp, name);
}

static void
perm_fmgr_info(Oid functionId, FmgrInfo *finfo)
{
    fmgr_info_cxt(functionId, finfo, TopMemoryContext);
}


/* Convert Parrot datatypes into PG Datum's */
Datum
plparrot_make_sausage(Parrot_Interp interp, Parrot_PMC pmc, FunctionCallInfo fcinfo)
{
    char *str, *pgstr;
    plparrot_proc_desc *prodesc;
    HeapTuple procTup, typeTup;
    Form_pg_proc procStruct;
    Form_pg_type typeStruct;

    /* elog(NOTICE, "starting sausage machine"); */
    if (Parrot_PMC_isa(interp,pmc,create_string_const("Integer"))) {
        return Int32GetDatum(Parrot_PMC_get_integer(interp,pmc));
    } else if (Parrot_PMC_isa(interp,pmc,create_string_const("String"))) {
        str   = Parrot_str_to_cstring(interp, Parrot_PMC_get_string(interp,pmc));
        pgstr = pstrdup(str);
        Parrot_str_free_cstring(str);

        procTup = SearchSysCache(PROCOID, ObjectIdGetDatum(fcinfo->flinfo->fn_oid), 0, 0, 0);
        procStruct = (Form_pg_proc) GETSTRUCT(procTup);

        prodesc = (plparrot_proc_desc *) malloc(sizeof(plparrot_proc_desc));
        /* TODO: check for out of memory errors */
        MemSet(prodesc, 0, sizeof(plparrot_proc_desc));
        typeTup = SearchSysCache(TYPEOID, ObjectIdGetDatum(procStruct->prorettype), 0, 0, 0);
        if (!HeapTupleIsValid(typeTup))
        {
            elog(ERROR, "cache lookup failed for type %u", procStruct->prorettype);
        }
        typeStruct = (Form_pg_type) GETSTRUCT(typeTup);
        perm_fmgr_info(typeStruct->typinput, &(prodesc->result_in_func));
        prodesc->result_typioparam = getTypeIOParam(typeTup);

        ReleaseSysCache(typeTup);
        ReleaseSysCache(procTup);

        return InputFunctionCall(&prodesc->result_in_func, pgstr, prodesc->result_typioparam, -1);

    } else if (Parrot_PMC_isa(interp,pmc,create_string_const("Float"))) {
        return Float8GetDatum(Parrot_PMC_get_number(interp,pmc));
    } else {
        elog(NOTICE,"CANNOT MAKE SAUSAGE");
        return (Datum) 0;
    }
}
