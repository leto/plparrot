NAME = plparrot
MODULE_big = plparrot
OBJS= plparrot.o
DATA_built = plparrot.sql
REGRESS_OPTS = --dbname=$(PL_TESTDB) --load-language=plpgsql
TESTS = $(wildcard t/sql/*.sql)
REGRESS = $(patsubst t/sql/%.sql,%,$(TESTS))

EXTRA_CLEAN = 

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

PARROTINCLUDEDIR = $(shell parrot_config includedir)
PARROTVERSIONDIR = $(shell parrot_config versiondir)
PARROTINC        = "$(PARROTINCLUDEDIR)$(PARROTVERSIONDIR)"
PARROTLDFLAGS    = $(shell parrot_config ldflags)
PARROTLINKFLAGS  = $(shell parrot_config inst_libparrot_linkflags)
PARROTLIBDIR     = $(shell parrot_config libdir)
PARROTP6OBJECT   = $(PARROTLIBDIR)$(PARROTVERSIONDIR)/library/P6object.pbc

# We need to do various things with various versions of PostgreSQL.
# VERSION     = $(shell $(PG_CONFIG) --version | awk '{print $$2}')
# PGVER_MAJOR = $(shell echo $(VERSION) | awk -F. '{ print ($$1 + 0) }')
# PGVER_MINOR = $(shell echo $(VERSION) | awk -F. '{ print ($$2 + 0) }')
# PGVER_PATCH = $(shell echo $(VERSION) | awk -F. '{ print ($$3 + 0) }')

override CPPFLAGS := -I$(PARROTINC) -I$(srcdir) $(CPPFLAGS)
override CFLAGS := $(PARROTLDFLAGS) $(PARROTLINKFLAGS) $(CFLAGS) -D'PARROTP6OBJECT="$(PARROTP6OBJECT)"'

test: all
	psql -AX -f $(TESTS)
