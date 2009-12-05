#include "postgres.h"
#include "executor/spi.h"
#include "commands/trigger.h"
#include "fmgr.h"
#include "access/heapam.h"
#include "utils/syscache.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"

/*
Figure out how to include these properly
#include "parrot/embed.h"
#include "parrot/debugger.h"
#include "parrot/runcore_api.h"
*/


PG_MODULE_MAGIC;

Datum plparrot_call_handler(PG_FUNCTION_ARGS);
void plparrot_elog(int level, char *message);

PG_FUNCTION_INFO_V1(plparrot_call_handler);

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    PG_RETURN_VOID();
}

void
plparrot_elog(int level, char *message)
{
    elog(level, "%s", message);
}
