#include "postgres.h"
#include "executor/spi.h"
#include "commands/trigger.h"
#include "fmgr.h"
#include "access/heapam.h"
#include "utils/syscache.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_type.h"


PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(plparrot_call_handler);

Datum
plparrot_call_handler(PG_FUNCTION_ARGS)
{
    PG_RETURN_VOID();
}
